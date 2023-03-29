FROM node:18-slim

WORKDIR /app

COPY ./package*.json /app/

RUN npm install --unsafe-perm --ignore-scripts

COPY . /app/

EXPOSE 3000

CMD ["yarn", "start"]