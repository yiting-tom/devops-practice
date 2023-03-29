FROM node:18-slim

WORKDIR /app

COPY ./package*.json .

RUN npm install --unsafe-perm --ignore-scripts

COPY . .

EXPOSE 3000

CMD ["yarn", "start"]