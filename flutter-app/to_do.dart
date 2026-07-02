//TODOS-{
//1) Make market memory page search dynamic with api, now its a static with some coins, 
//2) Add 2 section on tread-now and ai analysis screen funding rate and IO and liqudation 
//3) On tread-now page if i search coin "A" no w i stay there 5 min and then i search coin "B" then again search coin "A", now i get the A coin previous data now new data, i have to refresh to get new data
//}


//REF for 2 no point
// New Market Socket Events Added!
// I have fully implemented the rolling memory WebSocket system for liquidations, and added your new history events to the socket server.

// Because this relies on WebSockets, there are zero rate limit penalties, and it will run completely free forever!

// 1. Liquidation History (Real-Time Rolling Memory)
// Event to emit from frontend: coin:getLiquidations Payload to send: { "symbol": "BTCUSDT" } Event you will receive back: coin:liquidations

// How it works: The server is now constantly listening to the Binance forceOrder stream in the background. Every single liquidation across the entire market is silently caught and pushed into our new liquidationMemory vault. It holds onto them for exactly 60 minutes, automatically deleting older ones.

// When you ask for them, you will receive a response like this:

// json

// {
//   "symbol": "BTCUSDT",
//   "count": 45,
//   "longsRektUsd": 1500000.50,
//   "shortsRektUsd": 200000.00,
//   "recentEvents": [ ... array of the last 20 raw liquidation objects ... ]
// }
// IMPORTANT

// Warm-Up Period Because this is a rolling memory, when you restart your backend server, the memory starts empty. It will take a few minutes of real market activity for the liquidations to start showing up, and exactly 60 minutes to build a "full 1-hour chart".

// 2. Funding Rate & Open Interest History
// Event to emit from frontend: coin:getHistory Payload to send: { "symbol": "BTCUSDT" } Event you will receive back: coin:history

// How it works: When you request this, the server grabs the absolute latest Funding Rate (either from the live socket cache or from Binance directly) and fetches the last 24 hours of Open Interest (OI) in 1-hour candles.

// When you ask for them, you will receive a response like this:

// json

// {
//   "symbol": "BTCUSDT",
//   "fundingRate": 0.0001,
//   "oiHistory": [ ... array of open interest data ... ]
// }
// Next Steps
// You just need to restart your node server (npm run dev) for it to immediately connect to the new forceOrder streams and start recording liquidations!