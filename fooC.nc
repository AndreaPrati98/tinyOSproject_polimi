#include "Timer.h"
#include "foo.h"
#include "printf.h"

module fooC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as Timer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;
  bool mask[3] = {0, 0, 0};  // service variable for printing the led status
  
  event void Boot.booted() {
    call AMControl.start();
  	// start the radio
  }

// -----------------------------------------------------
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      	// here we setup the timers according with the nodeID
		switch(TOS_NODE_ID) {
		
			case 1:
				call Timer.startPeriodic( 1000 ); // 1 Hz
				//printf("\n NodeID: %d\n", TOS_NODE_ID);
				break;	
			
			case 2:
				call Timer.startPeriodic( 333 ); // 3 Hz
				//printf("\n NodeID: %d\n", TOS_NODE_ID);
				break;
		
			case 3:
				call Timer.startPeriodic( 200 ); // 5 Hz
				//printf("\n NodeID: %d\n", TOS_NODE_ID);
				break;
			
			default:
				call Timer.startPeriodic( 2000 ); // 0.5 Hz - default (example) option not used in the project
				printf("\n Too many nodes \n");
				break;
			
		}
    
    }
    else {
      call AMControl.start();
    }
  }
// -----------------------------------------------------

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
// -----------------------------------------------------
  
  event void Timer.fired() {

    if (locked) {
      return;
      
    } else {
		fooMessage_t* rcm = (fooMessage_t*)call Packet.getPayload(&packet, sizeof(fooMessage_t));
    	if (rcm == NULL) {
			return;
		}

		rcm->counter = counter; //we enter the struct to get counter
		rcm->nodeID = TOS_NODE_ID; // we enter the struct to get nodeID
		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(fooMessage_t)) == SUCCESS) {
			locked = TRUE;
      	}
    }
  }
// -----------------------------------------------------

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    // if we receive a msg, we increase the counter
    counter++;
    
    
    if (len != sizeof(fooMessage_t)) {return bufPtr;}
    
    else {
      fooMessage_t* rcm = (fooMessage_t*)payload;
      
      if ( (rcm -> counter % 10) == 0) {
        // if counter mod 10 == 0, turn off all the leds
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
		mask[0] = 0;
		mask[1] = 0;
		mask[2] = 0;
		
      } else if( (rcm -> nodeID) == 1) {
      	call Leds.led0Toggle();
		mask[0] = !mask[0];
		
      } else if( (rcm -> nodeID) == 2) {
      	call Leds.led1Toggle();
		mask[1] = !mask[1];
		
      } else if( (rcm -> nodeID) == 3) {
      	call Leds.led2Toggle();
		mask[2] = !mask[2];
		
      } else {
      	printf("\n\n ??\_(???)_/?? \n\n"); //easter egg
      
      }
      
      if(TOS_NODE_ID==2){
		  //here we print the nodeID and the attached status to debug and take the result for submiting
		  printf("Sender NodeID: %d, CounterMsg: %d, Mote status: %d%d%d\n", rcm -> nodeID, rcm -> counter, mask[2], mask[1], mask[0]);
	  }
      
      return bufPtr;
    }
    
    
  }


}
