# PostgreSQL Setup Help

## Create the database manually

Open pgAdmin, DBeaver, psql, or your PostgreSQL terminal and run:

```sql
CREATE DATABASE world_empire;
```

## Example local DATABASE_URL

```env
DATABASE_URL=postgres://postgres:your_password@localhost:5432/world_empire
```

Replace `your_password` with the password you chose when installing PostgreSQL.

## If port 5432 is already used

Another PostgreSQL instance is already running. Either use that one, or change the Docker Compose port mapping.

## HeidiSQL note

You can use HeidiSQL only as a visual database manager if you want, but the actual database server is PostgreSQL. The game server connects to PostgreSQL through `DATABASE_URL`.
