CREATE DATABASE mattermost;
CREATE USER mmuser WITH PASSWORD 'MATTERMOST_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE mattermost to mmuser;