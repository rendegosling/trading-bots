#property strict

string BotName = "MAbot";
int MaxTrades = 1;
int Magic = 1234;
int Slippage = 10;
int SMAFast = 145;
int SMASlow = 250;
int MaxCloseSpreadPips = 8;
double ProfitTarget = 20.0;
double StopLoss = -15.0;
double LotsToTrade = 0.2;


int OnInit()
{
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

}

void OnTick()
{
  // Print("***** Slow Moving Average: ", SlowMovingAverage)
  // Print("***** Fast Moving Average: ", FastMovingAverage)

  if (GetTotalOpenTrades() < MaxTrades && LongSetup())
  {
    int OrderResult = OrderSend(Symbol(), OP_BUY, LotsToTrade, Ask, Slippage, 0, 0, "Buy Order", Magic, 0, Green);
  }
  
  //if (GetTotalProfits() > ProfitTarget) CloseAllTrades();
  if (GetTotalProfits() < StopLoss) CloseAllTrades();
}

int GetTotalOpenTrades()
{
  int TotalTrades = 0;

  for (int t=0; t<OrdersTotal(); t++)
  {
    if(OrderSelect(t, SELECT_BY_POS, MODE_TRADES))
    {
      if(OrderSymbol() != Symbol()) continue;
      if(OrderMagicNumber() != Magic) continue;
      if(OrderCloseTime() != 0) continue;

      TotalTrades += 1;
    }
  }

  
  return TotalTrades;
}

bool LongSetup()
{
  double SlowMovingAverage = iMA(NULL, 0, SMASlow, 0, MODE_SMA, PRICE_CLOSE, 0);
  double SlowMovingAverage5 = iMA(NULL, 0, SMASlow, 0, MODE_SMA, PRICE_CLOSE, 3);
  double SlowMovingAverage15 = iMA(NULL, 0, SMASlow, 0, MODE_SMA, PRICE_CLOSE, 15);
  double SlowMovingAverage30 = iMA(NULL, 0, SMASlow, 0, MODE_SMA, PRICE_CLOSE, 30);

  double FastMovingAverage = iMA(NULL, 0, SMAFast, 0, MODE_SMA, PRICE_CLOSE, 0);
  double FastMovingAverage5 = iMA(NULL, 0, SMAFast, 0, MODE_SMA, PRICE_CLOSE, 3);
  double FastMovingAverage15 = iMA(NULL, 0, SMAFast, 0, MODE_SMA, PRICE_CLOSE, 15);
  double FastMovingAverage30 = iMA(NULL, 0, SMAFast, 0, MODE_SMA, PRICE_CLOSE, 30);

  return (
    (SlowMovingAverage > FastMovingAverage) &&
    (SlowMovingAverage5 < FastMovingAverage5) &&
    (SlowMovingAverage15 < FastMovingAverage15) &&
    (SlowMovingAverage30 < FastMovingAverage30)
  );
}

void CloseAllTrades()
{
  int CloseResult = 0;
  for(int t = 0; t < OrdersTotal(); t++)
  {
    if (OrderMagicNumber() != Magic) continue;
    if (OrderSymbol() != Symbol()) continue;
    if (OrderType() == OP_BUY) CloseResult = OrderClose(OrderTicket(), OrderLots(), Bid, MaxCloseSpreadPips, Red);
    if (OrderType() == OP_SELL) CloseResult = OrderClose(OrderTicket(), OrderLots(), Ask, MaxCloseSpreadPips, Green);
    t--;
  }

  return;
}

double GetTotalProfits()
{
  double TotalProfits = 0;
  for(int t = 0; t < OrdersTotal(); t++)
  {
    if (OrderSelect(t, SELECT_BY_POS, MODE_TRADES))
    {
      if (OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() != Symbol()) continue;
      if (OrderCloseTime() != 0) continue;
      TotalProfits += OrderProfit();
    }
  }
  return TotalProfits;
}
