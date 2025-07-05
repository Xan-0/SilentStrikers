FROM node:22-alpine

WORKDIR /home/app

COPY package*.json ./

RUN npm install

COPY . .
RUN npm run build

EXPOSE 80 8080

CMD ["node", "dist/main"]