const { query } = require('./db');

async function runEconomyTick(broadcast = () => {}) {
  const cities = (await query('SELECT * FROM cities')).rows;
  const summary = { cities: [], businesses: 0, taxes: 0 };

  for (const city of cities) {
    const biz = (await query('SELECT * FROM businesses WHERE city_id=$1 AND is_open=true', [city.id])).rows;
    const props = (await query('SELECT * FROM properties WHERE city_id=$1', [city.id])).rows;
    const jobs = biz.reduce((a,b)=>a + Number(b.employees), 0);
    const stockPressure = biz.length ? biz.reduce((a,b)=>a + Number(b.stock),0) / biz.length : 100;
    const serviceScore = Math.min(100, (jobs / Math.max(1, city.population)) * 2000 + Number(city.infrastructure) * 0.6);
    const happinessDelta = (serviceScore - 55) * 0.015 + (Number(city.safety) - 65) * 0.01 - (Number(city.business_tax) + Number(city.property_tax)) * 0.015;
    const popDelta = Math.round((Number(city.happiness) - 50) * 4 + biz.length * 8 - Math.max(0, 70 - Number(city.infrastructure)) * 3);
    const newHappy = Math.max(0, Math.min(100, Number(city.happiness) + happinessDelta));
    const newPop = Math.max(1000, Number(city.population) + popDelta);
    const demand = Math.max(30, Math.min(200, 70 + newHappy * 0.8 + biz.length * 2 - (stockPressure < 30 ? 20 : 0)));
    const rentIndex = Math.max(40, Math.min(250, 70 + newHappy * 0.5 + newPop / 5000));
    const cityTax = biz.reduce((a,b)=>a + Math.max(0, Number(b.cash) * Number(city.business_tax) / 10000), 0) + props.length * Number(city.property_tax);

    await query(`UPDATE cities SET population=$2,happiness=$3,demand_index=$4,rent_index=$5,treasury=treasury+$6,updated_at=now() WHERE id=$1`,
      [city.id, newPop, newHappy, demand, rentIndex, cityTax]);

    for (const b of biz) {
      const demandFactor = demand / 100;
      const sales = Math.min(Number(b.stock), Math.max(0, Math.round(Number(b.reputation)/10 * demandFactor * Math.random() + Number(b.employees) * demandFactor)));
      const revenue = sales * Number(b.price);
      const wages = Number(b.employees) * Number(b.wage) / 30;
      const tax = Math.max(0, revenue * Number(city.business_tax) / 100);
      const newStock = Math.max(0, Number(b.stock) - sales);
      const repDelta = sales > 0 ? 0.05 : -0.08;
      await query(`UPDATE businesses SET cash=cash+$2-$3-$4, stock=$5, reputation=GREATEST(0,LEAST(100,reputation+$6)) WHERE id=$1`,
        [b.id, revenue, wages, tax, newStock, repDelta]);
      await query('UPDATE users SET cash=cash+$2 WHERE id=$1', [b.owner_user_id, Math.max(0, revenue - wages - tax) * 0.25]);
      summary.businesses++;
      summary.taxes += tax;
    }

    summary.cities.push({ id: city.id, name: city.name, population: newPop, happiness: newHappy.toFixed(1), demand: demand.toFixed(1) });
  }

  await query('INSERT INTO economy_ticks(summary) VALUES($1)', [summary]);
  broadcast({ type: 'economy_tick', summary });
  return summary;
}

module.exports = { runEconomyTick };
