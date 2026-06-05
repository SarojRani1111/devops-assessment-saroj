FROM node:18-alpine

WORKDIR /app

COPY src/package*.json ./

RUN npm install --production

COPY src/ .

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

USER node

CMD ["node", "index.js"]