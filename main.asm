.eqv BMP_FILE_SIZE 230454
.eqv BYTES_PER_ROW 960


	.data
.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE

fname:	.asciz "source.bmp"
y: 	.byte 240
	.text
	
main:
	jal read_bmp
	jal find_black
	
find_black:
	li a0, 0
	li a1, 0
	li s9, 0x00000000
	li s8, 319
	li s4, 240

black_loop_row:
	beq a0, s8, next_row
	mv s10, a0
	jal get_pixel
	beq a0, s9, black
	addi a0, a0, 1
	mv a0, s10
	addi a0, a0, 1
	j black_loop_row
	
next_row:
	li a0, 0
	addi a1, a1, 1
	beq a1, s4, exit
	j black_loop_row
	
black:
	mv a0, s10
	jal go_right
	jal go_up
	jal go_left
	j exit
	
exit:	li 	a7,10		#Terminate the program
	ecall
	
	
	
go_right:
	mv s7, ra
right_loop:
	jal get_pixel
	bne a0, s9 end_right
	addi s6, s6 1
	addi s10, s10, 1
	mv a0, s10
	j right_loop

end_right:
	mv ra, s7
	addi s10, s10, -1
	mv t5, a1
	mv a3, s10
	srli s6, s6, 1
	ret
	
go_up:
	mv s7, ra	
	mv a0, s10
	addi s5, s5, 1
up_loop:
	jal get_pixel
	bne a0, s9, not_found
	beq s5, s6, end_up
	mv a0, s10
	addi a1, a1, 1
	addi s5, s5, 1
	j up_loop
	
end_up:
	addi a1, a1, 1
	mv a0, s10
	jal get_pixel
	beq a0, s9, not_found
	mv a5, a1
	j right_frame

right_frame:
	mv a1, t5
	addi s10, s10, 1
	mv, a0, s10
	
rf_loop:
	jal get_pixel
	beq a5, a1, end_rf
	beq a0, s9, not_found
	addi a1, a1, 1
	mv a0, s10
	j rf_loop
	
end_rf:
	addi s10, s10, -1
	mv ra, s7
	ret
	
go_left:
	mv s7, ra
	addi a1, a1, -1
	slli s6, s6, 1
	sub s5, s10, s6
	addi s5, s5, 1
	mv a0, s10
left_loop:
	ble a0, s5, not_found
	jal get_pixel
	bne a0, s9, go_down
	addi s10, s10, -1
	mv a0, s10
	j left_loop

go_down:
	mv a0, s10
	sub s5, a3, s10
	add a4, t5, s5
down_loop:
	beq a1, a4, left_again
	blt a1, t5, not_found
	jal get_pixel
	beq a0, s9, not_found
	addi a1, a1, -1
	mv a0, s10
	j down_loop
	
left_again:
	mv a0, s10
	addi a1, a1, 1
	
	
	
	
	
not_found:
	addi s10, s10, 1
	mv a0, s10
	mv a1, t5
	j black_loop_row
	
		
	
get_pixel:
#description: 
#	returns color of specified pixel
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - 0RGB - pixel color

	la t1, image		#adress of file offset to pixel array
	addi t1,t1,10
	lw t2, (t1)		#file offset to pixel array in $t2
	la t1, image		#adress of bitmap
	add t2, t1, t2		#adress of pixel array in $t2
	
	#pixel address calculation
	li t4,BYTES_PER_ROW
	mul t1, a1, t4 		#t1= y*BYTES_PER_ROW
	mv t3, a0		
	slli a0, a0, 1
	add t3, t3, a0		#$t3= 3*x
	add t1, t1, t3		#$t1 = 3x + y*BYTES_PER_ROW
	add t2, t2, t1	#pixel address 
	
	#get color
	lbu a0,(t2)		#load B
	lbu t1,1(t2)		#load G
	slli t1,t1,8
	or a0, a0, t1
	lbu t1,2(t2)		#load R
        slli t1,t1,16
	or a0, a0, t1
					
	jr ra

	
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push $s1
	sw s1, 0(sp)
#open file
	li a7, 1024
        la a0, fname		#file name 
        li a1, 0		#flags: 0-read file
        ecall
	mv s1, a0      # save the file descriptor
	
#check for errors - if the file was opened
#...

#read file
	li a7, 63
	mv a0, s1
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall
	
	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	jr ra
	
save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push s1
	sw s1, (sp)
#open file
	li a7, 1024
        la a0, fname		#file name 
        li a1, 1		#flags: 1-write file
        ecall
	mv s1, a0      # save the file descriptor
	
#check for errors - if the file was opened
#...

#save file
	li a7, 64
	mv a0, s1
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall
	
	lw s1, (sp)		#restore (pop) $s1
	addi sp, sp, 4
	jr ra


# ============================================================================
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#	a2 - 0RGB - pixel color
#return value: none

	la t1, image	#adress of file offset to pixel array
	addi t1,t1,10
	lw t2, (t1)		#file offset to pixel array in $t2
	la t1, image		#adress of bitmap
	add t2, t1, t2	#adress of pixel array in $t2
	
	#pixel address calculation
	li t4,BYTES_PER_ROW
	mul t1, a1, t4 #t1= y*BYTES_PER_ROW
	mv t3, a0		
	slli a0, a0, 1
	add t3, t3, a0	#$t3= 3*x
	add t1, t1, t3	#$t1 = 3x + y*BYTES_PER_ROW
	add t2, t2, t1	#pixel address 
	
	#set new color
	sb a2,(t2)		#store B
	srli a2,a2,8
	sb a2,1(t2)		#store G
	srli a2,a2,8
	sb a2,2(t2)		#store R

	jr ra
