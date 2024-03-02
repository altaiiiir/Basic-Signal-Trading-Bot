# Basic Signal Trading Bot

This project, is designed to automate trading strategies by leveraging various technical indicators and risk management techniques. The trading logic is uses MetaTrader 5 (MT5) Expert Advisor (EA), utilizing the MQL5 language.

## Features

- **Dynamic Risk Management:** Adjusts trading risk based on account performance, with customizable risk floor and cap.
- **Multiple Indicators for Signal Generation:**
  - **Relative Strength Index (RSI):** Utilized to identify overbought or oversold conditions.
  - **Moving Average Convergence Divergence (MACD):** Helps in determining the momentum direction.
  - **Parabolic SAR:** Used to determine the potential reversals in the market price direction.
  - **Bollinger Bands:** Provides insights into the volatility and price levels relative to moving averages.
  - **Average True Range (ATR):** Used for setting stop loss and take profit levels dynamically.

## Configuration Options

- `riskCap` and `riskFloor`: Define the maximum and minimum risk per trade.
- `stopLossPips` and `takeProfitPips`: Set the distance for stop loss and take profit orders in pips.
- Indicators settings like `rsiPeriod`, `upperRsi`, `lowerRsi`, `atrPeriod`, `bbPeriod`, and `bbDeviation` can be adjusted to fit different trading strategies and market conditions.

## Trading Logic

1. **Signal Detection:** The bot evaluates the current market conditions based on the configured indicators. A buy signal is generated when the market is deemed oversold (and vice versa for sell signals), among other criteria involving MACD, RSI, Parabolic SAR, and Bollinger Bands.
2. **Order Execution:** Upon identifying a valid trade signal, the bot executes a trade with dynamically calculated lot size, stop loss, and take profit levels.
3. **Risk Adjustment:** After each trade, the bot adjusts the risk level based on the change in account balance, ensuring that the trading strategy adapts to both winning and losing streaks.

## Installation

1. Copy the provided MQL5 code into the MetaTrader 5 Editor.
2. Compile the code to generate the executable EA.
3. Attach the EA to the desired chart, ensuring that the input parameters match your risk tolerance and strategy preferences.

## Contributing

Contributions to improve the bot or adapt it to different strategies are welcome. Please feel free to fork the repository, make your changes, and submit a pull request.

---
