#property strict

int MaxTrades = 1;
int Magic = 1111;
int Slippage = 10;
int MaxCloseSpreadPips = 8;
double ProfitTarget = 30.0;
double RiskPerTrade = -0.01;


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
  //CreateLabel(DoubleToString(iClose(NULL, 0, 0), Digits));
  CreateLabel(DoubleToString(GetStopLossAmount(), Digits));
  

  if (GetTotalOpenTrades() < MaxTrades)
  {
    if(BollingerLongSetup()) int result = OrderSend(Symbol(), OP_BUY, CalculateLots(), Ask, Slippage, 0, 0, "Buy Order", Magic, 0, Green);
    if(BollingerShortSetup()) int result = OrderSend(Symbol(), OP_SELL, CalculateLots(), Bid, Slippage, 0, 0, "Sell Order", Magic, 0, Green);
  }
  
  if (OrdersTotal() > 0) TrailStops();
  
  //if (GetTotalProfits() < GetStopLossAmount()) CloseAllTrades();
  if (GetTotalProfits() > ProfitTarget) CloseAllTrades();
  //
}

double GetStopLossAmount()
{
  return AccountBalance() * RiskPerTrade;
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

void CreateLabel(string label)
{
  ObjectCreate("P", OBJ_LABEL, 0, 0, 0);
  ObjectSetText("P", label, 20, "Arial", clrRed);
  ObjectSet("P", OBJPROP_CORNER, 1);
  ObjectSet("P", OBJPROP_XDISTANCE, 30.0);
  ObjectSet("P", OBJPROP_YDISTANCE, 60.0);
  return;
}

double BandsHigh()
{
  return iBands(NULL, 0, 20, 2, 0, PRICE_LOW, MODE_UPPER, 0);
}

double BandsLow()
{
  return iBands(NULL, 0, 20, 2, 0, PRICE_LOW, MODE_LOWER, 0);
}

bool Uptrend()
{
   double current_ma = iMA(NULL, 0, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   double current_ma_10 = iMA(NULL, 0, 50, 0, MODE_SMA, PRICE_CLOSE, 9);
   double current_low = iLow(NULL, 0, 0);
   return (current_ma_10 < current_ma) && (current_ma < current_low);
}

bool Downtrend()
{
   double current_ma = iMA(NULL, 0, 50, 0, MODE_SMA, PRICE_CLOSE, 0);
   double current_ma_10 = iMA(NULL, 0, 50, 0, MODE_SMA, PRICE_CLOSE, 9);
   double current_high = iHigh(NULL, 0, 0);
   return (current_ma_10 > current_ma)&& (current_ma > current_high);
}


bool CurrentCloseLowerThanBollingerLow()
{
  return iLow(NULL, 0, 0) < BandsLow();
}

bool CurrentCloseHigherThanBollingerHigh()
{
  return iHigh(NULL, 0, 0) > BandsHigh();
}

bool BollingerLongSetup()
{
  return Uptrend() && CurrentCloseLowerThanBollingerLow();
}

bool BollingerShortSetup()
{
  return Downtrend() && CurrentCloseHigherThanBollingerHigh();
}

double CalculateLots()
{
   return 0.2;
}

double CalculateStopLossLong(double price)
{
   return price - 500 * Point;
}

double CalculateTakeProfitLong(double price)
{
   return price + 500 * Point;
}

double CalculateStopLossShort(double price)
{
   return price + 500 * Point;
}

double CalculateTakeProfitShort(double price)
{
   return price - 500 * Point;
}

//+------------------------------------------------------------------+
//| Trailing stop function                                           |
//+------------------------------------------------------------------+
void TrailStops()
{
    int trailingStop = 300;
 
    for (int i = 0; i < OrdersTotal(); i++) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
  
        if (OrderSymbol() != Symbol()) {
            continue;
        }
  
        if(OrderType() == OP_BUY) {
            if (Bid - OrderOpenPrice() > trailingStop * Point && OrderStopLoss() < Bid - trailingStop * Point) {
                if (!OrderModify(OrderTicket(), OrderOpenPrice(), Bid - trailingStop * Point, OrderTakeProfit(), 0, Green)) {
                    Print("OrderModify error ",GetLastError());
                }
                return;
            }
        }
        
        if(OrderType() == OP_SELL) {
            if (Ask - OrderOpenPrice() < trailingStop * Point && OrderStopLoss() < Ask - trailingStop * Point) {
                if (!OrderModify(OrderTicket(), OrderOpenPrice(), Ask - trailingStop * Point, OrderTakeProfit(), 0, Green)) {
                    Print("OrderModify error ",GetLastError());
                }
                return;
            }
        }
    }
}
