the two statemachine.txt files contain the vhdl code of a microprocessor that works with a 64kb async RAM in order to upload it on xilinx or modelsim just copy paste the code into a file project that you created

same thing for the multiplier 

below is the microprocessor's components 
![image](https://github.com/user-attachments/assets/ddf26c86-7931-47b7-889b-ec641ce37701)

the purpose of the microprocessor is to read the instructions from the initialised bits in ram creating the instruction list (those being already initialised in the provided code but can be changed ) the instruction list starts at 0 and goes up to 2048

those instructions can be one the following 
![image](https://github.com/user-attachments/assets/4a52af97-cd22-4e44-8faf-61394bab7766)

the ram has 4096 empty adresses each being 16bits long making it 64kb in size
![image](https://github.com/user-attachments/assets/1889d8a2-36b7-4c2a-b4d1-eb33b1fed5e0)

the state machine also includes 3 registers one buffer and 2 muxes for different purposes
and an ALU that has 4 codes depending on which it executes a certain instruction from the table below
![image](https://github.com/user-attachments/assets/1b670885-c97f-4976-af55-360ea0659847)

the multiplier is a seperate entity and it does a 4bits by 4bits multiplication concurrently
![image](https://github.com/user-attachments/assets/b3258463-e31c-47f9-a33b-e777b632b465)

