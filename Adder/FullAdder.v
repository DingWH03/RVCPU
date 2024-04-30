module FullAdder (
    input A, B, Ci,
    output Sum, Co
);

assign Sum = A ^ B ^ Ci; // Sum bit
assign Co = (A & B) | (A & Ci) | (B & Ci); // Carry out

endmodule

