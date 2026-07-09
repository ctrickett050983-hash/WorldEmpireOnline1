class Broadcaster {
  constructor() {
    this.send = () => {};
  }

  setSender(sender) {
    this.send = sender;
  }

  broadcast(payload) {
    this.send(payload);
  }
}

module.exports = new Broadcaster();
