#include <Trade\Trade.mqh>  // Include the Trade.mqh library

//+------------------------------------------------------------------+
//|                                                   S&R EA.mq5     |
//|                        Copyright Terence Pillay Specifications       |
//+------------------------------------------------------------------+
#property copyright "Terence Pillay"
#property version   "1.00"
#property strict
input double Month_Inverse = 0;  // Month Inverse Swop Strategy
input double Risk_Percentage = 1.0;  // Risk as a percentage of balance
input int Look_Back_Period = 20;      // Period to look back for support and resistance (e.g., 96 = last 96 bars)
input int Min_Time_Between_Trades = 60; // Minimum minutes between trades
input double RR_Ratio = 2.0;         // Risk-to-reward ratio
input double Lot_Size = 1.0;         // Input lot size for trades
input double Stop_Loss_Number = 30;
input double Target_Profit_Number = 30;
input string Exclusion_Start_1 = "22:00"; // Start time for the first exclusion period
input string Exclusion_End_1 = "23:00";   // End time for the first exclusion period
input string Exclusion_Start_2 = "03:00"; // Start time for the second exclusion period
input string Exclusion_End_2 = "04:00";   // End time for the second exclusion period
int ValueAdd= 0;
int counterbuy = 0;
int countersell = 0;
datetime LastTradeTime = 0;
input string userKey;  // Input for the user-provided key

// Declare CTrade object for handling trade operations
CTrade trade;

// Function to generate the expected key based on the current month and year

// XOR encryption function (used for both encryption and decryption)
string XOREncryptDecrypt(string data, int key) {
    string result = "";
    for (int i = 0; i < StringLen(data); i++) {
        result += CharToString(StringGetCharacter(data, i) ^ key);
    }
    return result;
}
// Function to generate the key based on the current year and month
//string GenerateKey() {
//    datetime currentTime = TimeCurrent();  // Get current server time
//    MqlDateTime timeStruct;
//    TimeToStruct(currentTime, timeStruct);  // Convert datetime to MqlDateTime structure
//
//    int year = timeStruct.year;  // Extract year
//    int month = timeStruct.mon;  // Extract month
//
//    // Generate a key in the format "YYYYMM" (e.g., "202411")
//    string key = StringFormat("%04d%02d", year, month);  // Format as 202411
//
//    // XOR encrypt the key with a simple key (e.g., 12345)
//    string encryptedKey = XOREncryptDecrypt(key, 12345);
//
//    // Base64 encode the encrypted key
//    string encodedKey = Base64Encode(encryptedKey);
//
//    return encodedKey;  // Return the encoded key
//}

string GenerateKey() {
    datetime currentTime = TimeCurrent();  // Get current server time
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);  // Convert datetime to MqlDateTime structure

    int year = timeStruct.year;  // Extract year
    int month = timeStruct.mon;  // Extract month

    // Retrieve account details
    long accountNumber = AccountInfoInteger(ACCOUNT_LOGIN);   // Get account number


    // Combine account details and date into a base string
    string baseKey = StringFormat("%04d%02d|%d|%s", year, month, accountNumber);

    // XOR encrypt the key with a simple key (e.g., 12345)
    string encryptedKey = XOREncryptDecrypt(baseKey, 12345);

    // Base64 encode the encrypted key
    string encodedKey = Base64Encode(encryptedKey);

    return encodedKey;  // Return the encoded key
}


string Base64Encode(string data) {
    // Base64 encoding table
    const string base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    // Convert the string to a byte array
    uchar byteArray[];
    StringToCharArray(data, byteArray);
    
    string encoded = "";
    int len = ArraySize(byteArray);
    
    int i = 0;
    while (i < len) {
        int byte1 = byteArray[i++];
        int byte2 = (i < len) ? byteArray[i++] : 0;
        int byte3 = (i < len) ? byteArray[i++] : 0;
        
        encoded += base64chars[(byte1 >> 2) & 0x3F];
        encoded += base64chars[((byte1 << 4) & 0x3F) | ((byte2 >> 4) & 0x0F)];
        encoded += (i > len) ? "=" : base64chars[((byte2 << 2) & 0x3F) | ((byte3 >> 6) & 0x03)];
        encoded += (i > len + 1) ? "=" : base64chars[byte3 & 0x3F];
    }
    
    return encoded;
}

// Function to validate the user-provided key by decrypting it and checking against the expected key
bool ValidateKey(string userKey1) {
    string expectedKey = GenerateKey(); // Generate the expected key
        //Print("Invalid key. ",expectedKey, " ");
    string shortkey= GenerateShortKey(expectedKey);
            //Print("Invalid short key. ",shortkey, " ");
    // Decrypt the user-provided ke
    return (userKey1 == shortkey); // Compare the decrypted key with the expected key
}

// Function to calculate Swing High (Resistance)
double GetResistanceLevel() {
    double resistance = 0;
    
    // Loop through the recent bars to find the highest peak
    for (int i = 1; i < Look_Back_Period; i++) {
        double highCurrent = iHigh(_Symbol, PERIOD_M15, i);
        double highPrevious = iHigh(_Symbol, PERIOD_M15, i + 1);
        double highNext = iHigh(_Symbol, PERIOD_M15, i - 1);
        
        // Check if it's a swing high
        if (highCurrent > highPrevious && highCurrent > highNext) {
            resistance = highCurrent; // This is a swing high (resistance)
            break;  // You can find multiple resistances if needed, or break for the closest one
        }
    }

    return resistance;
}

// Function to calculate Swing Low (Support)
double GetSupportLevel() {
    double support = 0;

    // Loop through the recent bars to find the lowest trough
    for (int i = 1; i < Look_Back_Period; i++) {
        double lowCurrent = iLow(_Symbol, PERIOD_M15, i);
        double lowPrevious = iLow(_Symbol, PERIOD_M15, i + 1);
        double lowNext = iLow(_Symbol, PERIOD_M15, i - 1);

        // Check if it's a swing low
        if (lowCurrent < lowPrevious && lowCurrent < lowNext) {
            support = lowCurrent; // This is a swing low (support)
            break;  // You can find multiple supports if needed, or break for the closest one
        }
    }

    return support;
}

int OnInit() {

if(userKey!="5")
{
    if (!ValidateKey(userKey)) 
    { 

        Print("Invalid key. The Expert Advisor will not function.");
        return INIT_FAILED; // Stop the EA if the key is invalid
    }
}
else
{
 //datetime currentTime = TimeCurrent();  // Get current server time
 //   MqlDateTime timeStruct;
 //   TimeToStruct(currentTime, timeStruct);  // Convert datetime to MqlDateTime structure
 //   int year = timeStruct.year;
 //   if(year==2024)
 //   {
 //     Print("Key validated. The Expert Advisor is running.");
 //     return INIT_SUCCEEDED; // Continue running if the key is valid
 //   }
 
   if (MQLInfoInteger(MQL_TESTER)) {
        Print("EA is running in backtesting mode.");
        return INIT_SUCCEEDED; // Allow EA to run in backtesting
    }

    Print("EA is not running in the Strategy Tester. Live trading is disabled.");
    return INIT_FAILED; // Prevent EA from running outside backtesting
 
 
}
Print("Key validated. The Expert Advisor is running.");
    return INIT_SUCCEEDED; // Continue running if the key is valid

}
void StringToTimeExclusion(const string input1, int &hour, int &minute) {
    string hourStr = StringSubstr(input1, 0, 2);
    string minuteStr = StringSubstr(input1, 3, 2);
    hour = StringToInteger(hourStr);
    minute = StringToInteger(minuteStr);
}
bool IsTimeInExclusionPeriod(int currentHour, int currentMinute, 
                             int startHour, int startMinute, 
                             int endHour, int endMinute) {
    datetime currentTime = currentHour * 60 + currentMinute;
    datetime startTime = startHour * 60 + startMinute;
    datetime endTime = endHour * 60 + endMinute;

    // Check for a period crossing midnight
    if (startTime > endTime) {
        return (currentTime >= startTime || currentTime < endTime);
    } else {
        return (currentTime >= startTime && currentTime < endTime);
    }
}

// Main OnTick function
void OnTick() {
datetime currentTime = TimeCurrent();
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    
    // Convert input times to hours and minutes
    int startHour1, startMinute1, endHour1, endMinute1;
    int startHour2, startMinute2, endHour2, endMinute2;

    // Parse times for the first exclusion period
    StringToTimeExclusion(Exclusion_Start_1, startHour1, startMinute1);
    StringToTimeExclusion(Exclusion_End_1, endHour1, endMinute1);

    // Parse times for the second exclusion period
    StringToTimeExclusion(Exclusion_Start_2, startHour2, startMinute2);
    StringToTimeExclusion(Exclusion_End_2, endHour2, endMinute2);

    // Check if the current time falls within the exclusion periods
    if (IsTimeInExclusionPeriod(timeStruct.hour, timeStruct.min, startHour1, startMinute1, endHour1, endMinute1) ||
        IsTimeInExclusionPeriod(timeStruct.hour, timeStruct.min, startHour2, startMinute2, endHour2, endMinute2)) {
        return; // Skip trading during the excluded periods
    }
    // Ensure a minimum time between trades
    if (TimeCurrent() - LastTradeTime < Min_Time_Between_Trades * 60) return;

    double support = GetSupportLevel();
    double resistance = GetResistanceLevel();
    double price = iClose(_Symbol,PERIOD_CURRENT, 0);
    double stopLoss, takeProfit;

    // Define the maximum range of 100 points
    double maxRange = 100 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double resistanceTest=0;
    double supportTest=0;
    if(Month_Inverse==0){
      resistanceTest=resistance;
      supportTest=support;
    }else   
    {
      resistanceTest=support;
      supportTest=resistance;
    }
    // Buy condition: Price hits support
    if (price <= resistanceTest) {
        // Ensure Stop Loss is within 100 points from current price
        stopLoss = support - maxRange;  
        // Calculate Take Profit based on risk-to-reward ratio
        takeProfit = price + ((price - stopLoss) * RR_Ratio);

        // Ensure Take Profit is also within 100 points from current price
        if (takeProfit > price + maxRange) {
            takeProfit = price + maxRange;
        }

        // Ensure the stop loss and take profit are valid
        if (stopLoss < price - maxRange) {
            stopLoss = price - maxRange;  // Adjust SL to be within 100 points from current price
        }

        // Print trade details before executing the buy
        Print("Buy Trade Details:");
        Print("Price: ", price);
        Print("Stop Loss: ", stopLoss - Stop_Loss_Number);
        Print("Take Profit: ", takeProfit + Target_Profit_Number);

        // Use CTrade object for placing a Buy order with the input lot size
        if (trade.Buy(Lot_Size, _Symbol, price, stopLoss - Stop_Loss_Number, takeProfit + Target_Profit_Number, "S&R Buy")) {
            LastTradeTime = TimeCurrent();
            counterbuy = counterbuy + 1;
            Print("Buy trades so far: ", counterbuy);
        }
    }
    // Sell condition: Price hits resistance
    else if (price >= supportTest) {
        // Ensure Stop Loss is within 100 points from current price
        stopLoss = resistance + maxRange;  
        // Calculate Take Profit based on risk-to-reward ratio
        takeProfit = price - ((stopLoss - price) * RR_Ratio);

        // Ensure Take Profit is also within 100 points from current price
        if (takeProfit < price - maxRange) {
            takeProfit = price - maxRange;
        }

        // Ensure the stop loss and take profit are valid
        if (stopLoss > price + maxRange) {
            stopLoss = price + maxRange;  // Adjust SL to be within 100 points from current price
// In MQL5, if you want to adjust the stop loss (`stopLoss`) to be within 100 points from the current price, you need to ensure that the stop loss is calculated correctly based on the current price and the maximum allowable range. The code snippet you provided seems to be setting the stop loss above the current price, which might not be the intended behavior if you are dealing with a long position. For a short position, you would typically set the stop loss below the current price.
// 
// Here's an example of how you might adjust the stop loss to be within 100 points from the current price for both long and short positions:
// 

double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID); // Get the current price
double maxRange = 100 * _Point; // Define the maximum range in points

// For a long position
double stopLossLong = currentPrice - maxRange;
if (stopLossLong < currentPrice - 100 * _Point) {
    stopLossLong = currentPrice - 100 * _Point;
}

// For a short position
double stopLossShort = currentPrice + maxRange;
if (stopLossShort > currentPrice + 100 * _Point) {
    stopLossShort = currentPrice + 100 * _Point;
}

// Example usage
Print("Stop Loss for Long Position: ", stopLossLong);
Print("Stop Loss for Short Position: ", stopLossShort);

// 
// ### Explanation:
// - **`currentPrice`**: This is the current market price of the symbol.
// - **`maxRange`**: This is the maximum allowable range for the stop loss, set to 100 points.
// - **`stopLossLong`**: For a long position, the stop loss is set below the current price.
// - **`stopLossShort`**: For a short position, the stop loss is set above the current price.
// - The conditions ensure that the stop loss does not exceed 100 points from the current price in either direction.
// 
// Make sure to adjust the logic according to your specific trading strategy and whether you are dealing with long or short positions.
// 

        }

        // Print trade details before executing the sell
        Print("Sell Trade Details:");
        Print("Price: ", price);
        Print("Stop Loss: ", stopLoss + Stop_Loss_Number);
        Print("Take Profit: ", takeProfit - Target_Profit_Number);

        // Use CTrade object for placing a Sell order with the input lot size
        if (trade.Sell(Lot_Size, _Symbol, price, stopLoss + Stop_Loss_Number, takeProfit - Target_Profit_Number, "S&R Sell")) {
            LastTradeTime = TimeCurrent();
            countersell = countersell + 1;
            Print("Sell trades so far: ", countersell);
        }
    }
}
//string GenerateShortKey(string baseKey) {
//    uchar hash[16];
//    StringToCharArray(baseKey, hash,0,WHOLE_ARRAY,CP_UTF8);
//    uchar result[16];
//    uchar md5[16];
//    CryptEncode(CRYPT_HASH_MD5, hash, md5,result);
//    string shortKey = "";
//    for (int i = 0; i < 8; i++) { // Use first 8 bytes for a shorter key
//        shortKey += StringFormat("%02X", result[i]);
//    }
//    return shortKey;
//}
string GenerateShortKey(string inpout) {
    //string base64Key = Base64Encode(inpout);
    return StringSubstr(inpout, 26, 10)+"EA"; // Truncate to 16 characters
}