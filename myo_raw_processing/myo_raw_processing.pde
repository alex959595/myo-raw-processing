
import processing.serial.*;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.io.*;
import java.util.*;

Serial myPort;  // The serial port
boolean sendingCommand = false;
boolean waitEvent = false;
boolean OnEmg = false; 
boolean foundAddress = false;
ArrayList<Integer> bufferReadIn = new ArrayList<Integer>();
int[] addr = new int[6];


void setup() {
  // List all the available serial ports
  printArray(Serial.list());
  
  // Open the port you are using at the rate you want, automatically connects to the myo Armband "COM 3" on my pc
  myPort = new Serial(this, Serial.list()[0], 9600);
  println(myPort.hashCode() + " " + myPort.active());
  
  //End Scans any scans of program looking for the myo armband 
  end_scan();
  checkforEndScan();
  
  //Just a cautionary step to disconnect from any myo armband
  disconnect(byte(0));
  checkForDisconnect();
  disconnect(byte(1));
  checkForDisconnect();
  disconnect(byte(2));
  checkForDisconnect();
  
  //Signal is sent to see if Myo armband is available to connect to. 
  //If one is available returns the Address, This is a "Notify-only characteristic" returns until you end the scan
  //Needs to be updated to save address then connect to myo armband
  discover();
  checkForDiscover();
  
  //If the right Address in the discover, This will end the "Notify-only characteristic" of discover
  end_scan();
  checkforEndScan();
  
  //Uses the address from the discover to connect to the Myo Attribute. 
  //This will allow you to interact with the myo armband by reading and writing.
  connect();
  checkConnection();
  
  //These write commands are used to turn on the Myo Armband "Notify-only characteristic" on so Emg data will be sent.
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

//Command to discover armband
void discover(){
  foundAddress = true;
  println("discovering");
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
//Uses the addr that is retrieved during the discover option.
//Check if the characters exist in processing. ex: char(147) = '?' in processing, should be char(147) = '“'
   for(int i=0;i<addr.length;i++)
   {
     if(addr[i] == 147)
       bytes += '“';
     else
       bytes += char(addr[i]);
   }
//Hardcoded Address Starts here found in the discover. To find print "addr" at around 216 in the python code, Then put in below. 
  //bytes += char(118);
  //bytes += char(32);
  //bytes += char(179);
  //bytes += char(212);
  ////Character 147 is not registered in processing so Char(147) = '“'
  //bytes += '“';
  //bytes += char(249);
 //Stops here
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
  println("Checking for response to end_scan...");
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
  println("Checking to see if Disconnect...");
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
  println("Checking for response to from Discover...");
  while(foundAddress){
    // Dont know why this needs to be here.... but wont discover myo on my computer unless there is a print statement here!
    println("Scanning");
    while (myPort.available() > 0) {
      int inByte = myPort.read();
      char test = (char)inByte; 
      if(inByte == 128){
        foundAddress = false;
      }
      if(!foundAddress)
        bufferReadIn.add(inByte);
      println(inByte + " " + test + " ");
      sendingCommand = false;
    }
  }
  println("Addr is from index 6 to 11 " + bufferReadIn);
  for(int i=0; i<addr.length;i++)
    addr[i] = bufferReadIn.get(i+6);
  bufferReadIn.clear();
}

void onEmg(){
 // Splitting up the arrays on the end byte 128 seems to get results that work.
 // All sensors seemed to be mapped in List emgData I am creating.
 // Remove if condition and and print out bufferReaderIn to see all values currently being sent by Myo. 
 //There are some uneeded smaller arrays printing out I am just skipping over them for now in the if with "bufferReadIn.size() > 24"
 while (myPort.available() > 0) {
    int inByte = myPort.read();
    if(inByte != 128){
      bufferReadIn.add(inByte);
    }
    else{
      if(bufferReadIn.size() > 24 && bufferReadIn.get(4) == 39){
        List<Integer> emgData = bufferReadIn.subList(8, bufferReadIn.size()-1);
        println(emgData);
      }
       bufferReadIn.clear();
    }  
  }
}

void checkConnection(){
 //Check Connnectiong Wait Event ins triggered waits until byte 128 is returned then proceeds to to next step.
 println("Checking to see if Connected to MyoArmband...");
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
 //Wait Event ins triggered waits until byte 128 is returned then proceeds to to next step.
 println("Wait event for Write Attributes...");
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