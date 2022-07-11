#include <Servo.h>

uint8_t buffer[20]; //Buffer needed to store data packet for transmission
int16_t data1 = 1;
int16_t data2 = 2;
int16_t data3 = 3;
int16_t data4 = 4;
bool debug = false;

uint8_t buffer2[20];

Servo myservo;  // create servo object to control a servo

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  myservo.attach(9,600,2600);  // (pin, min, max) For Alignment
}

// or for example
// case 0:
// int sensorValueOrX = digitalRead(0);
// Serial.print(sensorValueOrX);
// break;

  // put your main code here, to run repeatedly: 
void loop(){
  for (uint8_t i = 0; i<7; i++) {
    switch (i) {
      case 0:
      myservo.write(0);
      Serial.print(0); // digitalRead the pin
      delay(1000);
      break;
      case 1:
      myservo.write(45);
      Serial.print(45); // digitalRead the pin
      delay(1000);
      break;
      case 2:
      myservo.write(90);
      Serial.print(90); // digitalRead the pin
      delay(1000);
      break;
      case 3:
      myservo.write(180);
      Serial.print(180); // digitalRead the pin
      delay(1000);
      break;
      case 4:
      myservo.write(0);
      Serial.print(0); // digitalRead the pin
      delay(1000);
      break;
      case 5:
      myservo.write(45);
      Serial.print(45); // digitalRead the pin
      delay(1000);
      break;
      case 6:
      myservo.write(90);
      Serial.print(90); // digitalRead the pin
      delay(1000);
      break;
    }
    if (i < 8)
      Serial.print(" ");
  }
  Serial.print('\r');
  delay(5);
}
uint8_t variableA = {0x00};
void plot(int16_t data1, int16_t data2, int16_t data3, int16_t data4) {
  int16_t pktSize;
  
  buffer[0] = 0xCDAB;             //SimPlot packet header. Indicates start of data packet
  //buffer[1] = 4*sizeof(int16_t);      //Size of data in bytes. Does not include the header and size fields
  buffer[1] = 1;
  buffer[2] = 5;
  buffer[3] = 6;
  buffer[4] = 7;
  buffer[5] = 8;
    
  pktSize = 2 + 2 + (4*sizeof(int16_t)); //Header bytes + size field bytes + data
  
  if (!debug) {
    Serial.print(data1);
    Serial.print(" ");
    Serial.print(data2);
    Serial.print(" ");
    Serial.print(data3);
    Serial.print(" ");
    Serial.print(data4);
    Serial.print('\r');
  }
  else {
    Serial.print("Size: ");
    Serial.println(pktSize, HEX);
    for (int i = 0; i<pktSize; i++) {
      Serial.print(buffer[i], HEX);
      Serial.print(" ");
    }
    Serial.println();
  }
}
