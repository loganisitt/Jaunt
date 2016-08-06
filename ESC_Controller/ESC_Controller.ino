#include <Servo.h>

#include <SPI.h>
#include <EEPROM.h>
#include <boards.h>
#include <RBL_nRF8001.h>
#include <stdio.h>
#include <string.h>

Servo ESC;

void setup() {

  ble_begin();
  ble_set_name("Jaunt");
  
  ESC.attach(9);
  ESC.write(95);
  delay(10000);
}

char speed[3];
int count = 0;

void loop() {
  if ( ble_available() ) {
    Serial.println("BLE AVAILABLE");
    while ( ble_available() ) {
        speed[count] = ble_read();
        count++;
    } 
    int dec = 0, i, j, len;
    len = strlen(speed);
    for (i=0; i<len; i++) {
      dec = dec * 10 + ( speed[i] - '0' );
    }
    ESC.write(dec); 
    count = 0;
  }
  ble_do_events();
}
