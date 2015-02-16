FROM node:latest

RUN git clone https://github.com/tobie/feedme.git /feedme
WORKDIR /feedme
RUN npm install
ADD options.json /feedme/
CMD ["node", "index.js"]