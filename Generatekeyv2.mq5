//+------------------------------------------------------------------+
//|                                                 KeyGeneratorEA   |
//|                         Key Generator EA for Forex Accounts      |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property version   "1.00"
#property strict

// Inputs for custom account number and generation interval
input long CustomAccountNumber = 0;         // User-provided account number (0 uses current account)
input int KeyGenerationInterval = 60;      // Interval in seconds to regenerate the key

// Global variable to track the last key generation time
datetime lastGenerationTime = 0;

// XOR encryption function
string XOREncryptDecrypt(string data, int key) {
    string result = "";
    for (int i = 0; i < StringLen(data); i++) {
        result += CharToString(StringGetCharacter(data, i) ^ key);
    }
    return result;
}

// Base64 encoding function
string Base64Encode(string data) {
    const string base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
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

// Function to generate the key
string GenerateKey(long accountNumber) {
    datetime currentTime = TimeCurrent();  // Get current server time
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);  // Convert datetime to MqlDateTime structure

    int year = timeStruct.year;  // Extract year
    int month = timeStruct.mon;  // Extract month


    // Combine account details and date into a base string
    string baseKey = StringFormat("%04d%02d|%d|%s", year, month, accountNumber);

    // XOR encrypt the key with a simple key (e.g., 12345)
    string encryptedKey = XOREncryptDecrypt(baseKey, 12345);

    // Base64 encode the encrypted key
    string encodedKey = Base64Encode(encryptedKey);

    return encodedKey;  // Return the encoded key
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    // Get the current server time
    datetime currentTime = TimeCurrent();

    // Define the date January 1, 2025
    datetime stopDate = D'2025.06.01 00:00';

    // Check if the current date is greater than the specified stop date
    if (currentTime > stopDate) {
        Print("The date is beyond January 1, 2025. Stopping execution.");
        ExpertRemove();  // Stops the Expert Advisor from executing further
        return INIT_FAILED;  // Return failed initialization
    }

    Print("KeyGeneratorEA initialized.");
    return INIT_SUCCEEDED;  // Successful initialization
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("KeyGeneratorEA deinitialized.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Check if it's time to generate a new key
    if (TimeCurrent() - lastGenerationTime >= KeyGenerationInterval) {
        lastGenerationTime = TimeCurrent(); // Update the last generation time

        // Determine the account number
        long accountNumber = CustomAccountNumber;
        if (CustomAccountNumber == 0) {
            accountNumber = CustomAccountNumber; // Use current account if no input
        }

        // Generate the key
        string generatedKey = GenerateKey(accountNumber);
         string shortkey=GenerateShortKey(generatedKey);
        // Print and alert the generated key
      
         Print("Short Key for Account");
         Print(shortkey);
          Print("Short Key for Account");
         Print(generatedKey);
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
// Shortened key function