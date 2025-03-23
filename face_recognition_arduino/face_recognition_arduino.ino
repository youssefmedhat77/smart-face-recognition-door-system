#include <Servo.h>

Servo myServo;
int servoPin = 9; // Connect servo to pin 9
String command = "";

void setup() {
    myServo.attach(servoPin);
    myServo.write(0); // Start at 0°
    Serial.begin(9600);
}

void loop() {
    if (Serial.available()) {
        command = Serial.readStringUntil('\n');
        command.trim();

        if (command == "OPEN") {
            myServo.write(90); // Move servo to 90°
            Serial.println("Servo at 90°");
        }
        else if (command == "CLOSE") {
            myServo.write(0); // Move servo back to 0°
            Serial.println("Servo at 0°");
        }
        else if (command == "EXIT") {
            Serial.println("Exiting...");
        }
    }
}
