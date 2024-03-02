//+------------------------------------------------------------------+
//|                                         Basic Signal Trading Bot |
//|                                         Mohamed Alturfi          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Indicators\Indicators.mqh>

CTrade trade;

// Global variables
int MagicNumber = 1;
double riskPerTrade = 1;

// Variable Inputs
input double riskCap = 5.0;
input double riskFloor = 0.1;
input int stopLossPips = 50;
input int takeProfitPips = 60;
input int rsiPeriod = 10;
input int upperRsi = 70;
input int lowerRsi = 30;
input int atrPeriod = 7;
input int volumeThreshold = 1000;
input double sarMax = 0.2;
input double sarStep = 0.01;
input int bbPeriod = 20;
input double bbDeviation = 2;

double lastBalance;  // Variable to store the last known balance


// Initialization function
int OnInit()
   {
    InitializeTimers();
    return(INIT_SUCCEEDED);
   }

// Initialize timers
void InitializeTimers()
   {
   }

// Deinitialization function
void OnDeinit(const int reason)
   {
    EventKillTimer();
   }

// Function called on every tick
void OnTick()
   {
    MqlDateTime currTime;
    TimeToStruct(TimeCurrent(), currTime);

// Check if the Forex market is open
    if(IsForexMarketOpen(currTime.day_of_week, currTime.hour))
       {
        AdjustRisk();
        ExecuteTradingLogic();
       }
   }

// Check if the Forex market is open
bool IsForexMarketOpen(int dayOfWeek, int hour)
   {
    return (dayOfWeek >= 1 && dayOfWeek <= 5 && !(dayOfWeek == 5 && hour >= 24));
   }

// Global variable to track the last MACD main value
double lastMacdMain = 0;

// Execute trading logic based on MACD
void ExecuteTradingLogic()
   {
    int macdHandle = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);

    double macdMain[], macdSignal[];
    ArraySetAsSeries(macdMain, true);
    ArraySetAsSeries(macdSignal, true);

    CopyBuffer(macdHandle, 0, 0, 1, macdMain);
    CopyBuffer(macdHandle, 1, 0, 1, macdSignal);

    double rsiValue = iRSI(_Symbol, PERIOD_CURRENT, rsiPeriod, PRICE_CLOSE);
    double parabolicSAR = iSAR(_Symbol, PERIOD_CURRENT, sarStep, sarMax);

    double upperBand[], middleBand[], lowerBand[];
    ArraySetAsSeries(upperBand, true);
    ArraySetAsSeries(middleBand, true);
    ArraySetAsSeries(lowerBand, true);

    int bbHandle = iBands(_Symbol, PERIOD_CURRENT, bbPeriod, 0, bbDeviation, PRICE_CLOSE);
    CopyBuffer(bbHandle, 0, 0, 1, upperBand);
    CopyBuffer(bbHandle, 1, 0, 1, middleBand);
    CopyBuffer(bbHandle, 2, 0, 1, lowerBand);

    if(IsBuySignal(macdMain[0], macdSignal[0], rsiValue, parabolicSAR, lowerBand[0]) && !IsTradeOpen())
       {
        PlaceLongOrder();
       }
    else
        if(IsSellSignal(macdMain[0], macdSignal[0], rsiValue, parabolicSAR, upperBand[0]) && IsTradeOpen())
           {
            PlaceSellOrder();
           }

    lastMacdMain = macdMain[0];
   }

// Check if it's a Buy signal
bool IsBuySignal(double macdMain, double macdSignal, double rsiValue, double parabolicSAR, double lowerBand)
   {
    int volume = iVolume(_Symbol, PERIOD_CURRENT, 0);
    double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    MqlTick lastTick;
    SymbolInfoTick(_Symbol, lastTick);

    return (macdMain > macdSignal && lastMacdMain <= macdSignal && rsiValue < upperRsi && volume > volumeThreshold && parabolicSAR > askPrice && lastTick.last < lowerBand);
   }

// Check if it's a Sell signal
bool IsSellSignal(double macdMain, double macdSignal, double rsiValue, double parabolicSAR, double upperBand)
   {
    int volume = iVolume(_Symbol, PERIOD_CURRENT, 0);
    double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    MqlTick lastTick;
    SymbolInfoTick(_Symbol, lastTick);

    return (macdMain < macdSignal && lastMacdMain >= macdSignal && rsiValue > lowerRsi && volume > volumeThreshold && parabolicSAR < bidPrice && lastTick.last > upperBand);
   }

// Check if a trade is open
bool IsTradeOpen()
   {
    return (PositionsTotal() > 0);
   }

// Place a sell order
void PlaceSellOrder()
   {
    trade.PositionClose(_Symbol);
   }

// Place a long order with SL/TP
void PlaceLongOrder()
   {
    double atrValue = iATR(_Symbol, PERIOD_CURRENT, atrPeriod);
    double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    askPrice = NormalizeDouble(askPrice, _Digits);

    double stopLoss = askPrice - (atrValue * stopLossPips * _Point);
    stopLoss = NormalizeDouble(stopLoss, _Digits);

    double takeProfit = askPrice + (atrValue * takeProfitPips * _Point);
    takeProfit = NormalizeDouble(takeProfit, _Digits);

    double lotSize = CalculateLotSize(riskPerTrade, askPrice - stopLoss);

    trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lotSize, askPrice, stopLoss, takeProfit);
   }

// Place a short order with SL/TP
void PlaceShortOrder()
   {
    double atrValue = iATR(_Symbol, PERIOD_CURRENT, atrPeriod);
    double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bidPrice = NormalizeDouble(bidPrice, _Digits);

    double stopLoss = bidPrice + atrValue * stopLossPips * _Point;
    stopLoss = NormalizeDouble(stopLoss, _Digits);

    double takeProfit = bidPrice - atrValue * takeProfitPips * _Point;
    takeProfit = NormalizeDouble(takeProfit, _Digits);

    double lotSize = CalculateLotSize(riskPerTrade, bidPrice - takeProfit);

    trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lotSize, bidPrice, stopLoss, takeProfit);
   }

// Adjust risk based on account performance
void AdjustRisk()
   {
    double currentBalance = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

    if(lastBalance == 0)
       {
        lastBalance = currentBalance;  // Initialize lastBalance on the first run
        return;
       }

//double rateOfChange = (currentBalance - lastBalance) / lastBalance;
//riskPerTrade += rateOfChange;  // Adjust risk based on rate of change of balance

    double balanceChange = currentBalance - lastBalance;

    if(balanceChange > 0)
       {
        // Increase risk by 0.1% if balance increased since last check
        riskPerTrade += 0.1;
       }
    else
        if(balanceChange < 0)
           {
            // Decrease risk by 0.2% if balance decreased since last check
            riskPerTrade -= 0.2;
           }

    if(riskFloor > riskCap)
       {
        return;
       }

// Clamp riskPerTrade between riskFloor and riskCap
    riskPerTrade = MathMax(riskFloor, MathMin(riskPerTrade, riskCap));
    riskPerTrade = MathMax(0, riskPerTrade);  // Ensure riskPerTrade is not negative

    lastBalance = currentBalance;  // Update lastBalance for next comparison
   }

// Calculate lot size based on risk percentage and stop loss distance
double CalculateLotSize(double risk, double slDistance)
   {
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    if(tickSize * tickValue * lotStep == 0)
       {
        return 0;
       }

    double riskMoney = AccountInfoDouble(ACCOUNT_MARGIN_FREE) * (risk / 100);
    double moneyLotStep = (slDistance / tickSize) * tickValue * lotStep;

    if(moneyLotStep == 0)
       {
        return 0;
       }

    double lot = (riskMoney / moneyLotStep) * lotStep;
    lot = NormalizeDouble(lot, 2);
    return lot;
   }
//+------------------------------------------------------------------+
