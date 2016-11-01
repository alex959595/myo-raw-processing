  
// Example by Tom Igoe

import processing.serial.*;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.io.*;
import java.util.*;

Serial myPort;  // The serial port
boolean sendingCommand = false;
boolean waitEvent = false;
boolean OnEmg = false; 
ArrayList<Integer> bufferReadIn = new ArrayList<Integer>();


void setup() {
  // List all the available serial ports
  printArray(Serial.list());
  // Open the port you are using at the rate you want:
  myPort = new Serial(this, Serial.list()[0], 9600);
  println(myPort.hashCode() + " " + myPort.active());
  end_scan();
  checkforEndScan();
  disconnect(byte(0));
  checkForDisconnect();
  disconnect(byte(1));
  checkForDisconnect();
  disconnect(byte(2));
  checkForDisconnect();
  discover();
  checkForDiscover();
  end_scan();
  checkforEndScan();
  connect();
  checkConnection();
  byte[] writeEmg1 = {1,0};
  writeAttr(40,writeEmg1,2);
  waitEvent();
  byte[] writeEmg2 = {1,3,1,1,0};
  writeAttr(25,writeEmg2,5);
  waitEvent();
  byte[] writeEmg3 = {1,3,1,1,1};
  writeAttr(25,writeEmg3,5);
  waitEvent();
    
   
}

void discover(){
  sendingCommand = true;
  println("discover");
  byte[] bytes = new byte[5];
  bytes[0] = 0;
  bytes[1] = 1;
  bytes[2] = 6;
  bytes[3] = 2;
  bytes[4] = 1;
  myPort.write(bytes);
}

void connect(){
  waitEvent = true;
  println("connect");
  String bytes = "";
  bytes += char(0);
  bytes += char(15);
  bytes += char(6);
  bytes += char(3);
  bytes += char(118);
  bytes += char(32);
  bytes += char(179);
  bytes += char(212);
  //Character 147 is not registered in processing so Char(147) = '“'
  bytes += '“';
  bytes += char(249);
  bytes += char(0);
  bytes += char(6);
  bytes += char(0);
  bytes += char(6);
  bytes += char(0);
  bytes += char(64);
  bytes += char(0);
  bytes += char(0);
  bytes += char(0);
  System.out.println(bytes + " " + bytes.length() );
  myPort.write(bytes);
}

void end_scan(){
  sendingCommand = true;
  println("Send Command to end_scan");
  String bytes = "";
  bytes += char(0);
  bytes += char(0);
  bytes += char(6);
  bytes += char(4);
  myPort.write(bytes);
}

void disconnect(byte instance){
  sendingCommand = true;
  println("Send command to disconnect " + instance);
  byte[] bytes = new byte[5];
  bytes[0] = 0;
  bytes[1] = 1;
  bytes[2] = 3;
  bytes[3] = 0;
  bytes[4] = instance;
  myPort.write(bytes);
}

void readAttr(int attr)
{
  println("read Attr");
  String bytes = "";
  bytes += char(0);
  bytes += char(3);
  bytes += char(4);
  bytes += char(4);
  bytes += char(0);
  bytes += char(attr);
  bytes += char(0);
  System.out.println(bytes + " " + bytes.length() );
  myPort.write(bytes);
}

void writeAttr(int attr, byte[] values, int lengthOfValues)
{
  waitEvent = true;
  println("write Attr");
  String bytes = "";
  bytes += char(0);
  bytes += char((4+lengthOfValues));
  bytes += char(4);
  bytes += char(5);
  bytes += char(0);
  bytes += char(attr);
  bytes += char(0);
  bytes += char(lengthOfValues);
  for(int i =0;i<lengthOfValues;i++)
    bytes += char(values[i]);
  System.out.println(bytes + " " + bytes.length() );
  myPort.write(bytes);
}

void draw() {
    onEmg();
}

void checkforEndScan(){
  println("Checking for response to end_scan");
  while(sendingCommand)
  {
    while (myPort.available() > 0) {
      int inByte = myPort.read();
      char test = (char)inByte; 
      println(inByte + " " + test + " ");
      sendingCommand = false;
    }
  }
}
void checkForDisconnect(){
  println("Checking for response to Disconnect");
  while(sendingCommand)
  {
    while (myPort.available() > 0) {
      int inByte = myPort.read();
      char test = (char)inByte; 
      println(inByte + " " + test + " ");
      sendingCommand = false;
    }
  }
}

void checkForDiscover(){
  println("Checking for response to Discover");
  while(sendingCommand){
    while (myPort.available() > 0) {
      int inByte = myPort.read();
      char test = (char)inByte; 
      println(inByte + " " + test + " ");
      sendingCommand = false;
    }
  }
}

void onEmg(){
 while (myPort.available() > 0) {
    int inByte = myPort.read();
    if(inByte != 128){
      bufferReadIn.add(inByte);
    }
    else{
      if(bufferReadIn.size() > 24 && bufferReadIn.get(4) == 39){
          List<Integer> inputA = bufferReadIn.subList(8, bufferReadIn.size()-1);
        println(inputA);
      }
       bufferReadIn.clear();
    }  
  }
}

void checkConnection(){
 println("checkConnection");
 while(waitEvent){
  while (myPort.available() > 0) {
    int inByte = myPort.read();
    char test = (char)inByte;
    bufferReadIn.add(inByte);
    if(inByte == 128)
      waitEvent = false;
    println(inByte + " " + test + " ");
    sendingCommand = false;
  }
  //println(bufferReadIn);
  bufferReadIn.clear();
 }
}

void waitEvent(){
 println("Wait event");
 while(waitEvent){
  while (myPort.available() > 0) {
    int inByte = myPort.read();
    char test = (char)inByte;
    bufferReadIn.add(inByte);
    if(inByte == 128)
      waitEvent = false;
    println(inByte + " " + test + " ");
    sendingCommand = false;
  }
    bufferReadIn.clear();
 }

}