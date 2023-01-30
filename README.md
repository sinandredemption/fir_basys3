# Real-Time Audio Processing on Basys-3 FPGA

This project implements real-time audio processing using a Basys-3 FPGA board and a Pmod I2S2 digital audio interface. The audio processing is performed using low-pass, high-pass, band-pass, and moving average FIR filters.

### Hardware Requirements

- Basys-3 FPGA board
- [Pmod I2S2](https://digilent.com/shop/pmod-i2s2-stereo-audio-input-and-output/) digital audio interface

### Software Requirements

- GNU Octave or MATLAB for generating filter coefficients using the `filter_gen.m` script.
- Vivado Design Suite for synthesizing and implementing the FPGA design.

### Files

- `Baysys-3-Master.xdc`: Constraints file for the Basys-3 FPGA board.
- `fir_backend.sv`: Implementation of a single/dual channel FIR filter backend.
- `fir.sv`: Handles and connects the AXI stream to FIR filter backend
- `filter_gen.m`: MATLAB/Octave script to generate hexadecimal coefficients for a desired FIR filter
- `single_channel_fir_engine_tb.sv` and `dual_channel_fir_engine_tb.sv`: Testbenches for testing the FIR filter backend implementations.

### Steps to run the project

1. Generate filter coefficients using the `filter_gen.m` script in MATLAB or Octave.
2. Open Vivado Design Suite and create a new project.
3. Add the required files to the project and synthesize the design.
4. Run the testbench to verify the functionality of the FIR filters.
5. Connect the Pmod I2S2 digital audio interface to the FPGA on JA.
6. Implement the design on the Basys-3 FPGA board.

### Limitations

The performance of the FIR filters may be limited by the kernel length and the number of filter taps. A longer kernel length would result in better performance, but may require a larger FPGA or a more powerful processor to handle the increased computation, or a more sophisticated design.

### Conclusion

This project demonstrates the ability to implement real-time audio processing using FIR filters on a Basys-3 FPGA board and a Pmod I2S2 digital audio interface. The provided files and instructions should provide a starting point for further experimentation and customization of the audio processing capabilities.
