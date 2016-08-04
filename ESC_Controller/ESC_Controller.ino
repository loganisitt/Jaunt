#include <Servo.h>

Servo ESC;

void setup() {
  ESC.attach(9);
  ESC.write(95);
  delay(10000);
  for (int i = 100; i <= 180; i+= 5) {
    ESC.write(i);
    delay(5000);
  }
}

void loop() {

}
