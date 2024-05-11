.eqv BMP_FILE_SIZE 230454
.eqv BYTES_PER_ROW 960


	.data
.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE

fname:	.asciz "source.bmp"
msg:	.asciz "\n marker found!"
y: 	.byte 240
	.text
	
main:
	jal read_bmp
	jal find_black
	
find_black:
	la t1, image		#adress of file offset to pixel array
	addi t1,t1,10
	lw s2, (t1)		#file offset to pixel array in $t2
	la t1, image		#adress of bitmap
	add s2, t1, s2		#adress of pixel array in $t2
	
	li a0, 0		#beginning coordinates (0,0)
	li a1, 0
	li s8, 319		#width
	li s4, 240		#height

black_loop_row:
	bge a1, s4, exit	#end of file
	beq s10, s8, next_row	#end of row
	mv a0, s10		#save s10, to a0
	jal get_pixel		#check color of pixel at (a0, a1)
	beq a0, zero, black	#if its black, j to "black"		
	addi s10, s10, 1	#increment s10 (x value)
	j black_loop_row	
	
next_row:
	li s10, 0		#change x coordinate to 0
	addi a1, a1, 1		#go one row up
	beq a1, s4, exit	#if it wnet over the top, end
	j black_loop_row
	
black:
	mv a0, s10		#change a0 to x coordinate
	jal go_right		#go right until not black
	jal go_up		#go up until not black
	jal go_left
	j exit
	
exit:	li 	a7,10		#Terminate the program
	ecall
	
	
	
go_right:
	mv s7, ra		#save return address
right_loop:
	beq a0, s8, right_border	#reached right border of file
	jal get_pixel		#get color of pixel at a0,a1
	bne a0, zero end_right	#if not black, end_right
	addi s6, s6 1		#increment width counter
	addi s10, s10, 1	#icrement x coordinate
	mv a0, s10		#move s10 to a0
	j right_loop
right_border:
	addi a1, a1, 1		#go to next row
	li a0, 0		#change x cord to 0
	j black_loop_row
end_right:
	mv ra, s7		#get return value back to ra
	addi s10, s10, -1	#step one x coord back
	mv t5, a1		#save y cord to t5    (those will be the return values if the marker is indeed found)
	mv a3, s10		#save x cord to a3
bottom_frame:
	sub s10, s10, s6	#go back to beggining
	addi s10, s10, 1	#add 1 for correction
	addi a1, a1, -1		#check the row under the original black one
	mv a0, s10	
b_loop:
	bgt a0, a3, end_bf	#if checked the entire bottom, end
	jal get_pixel		#check value of pixel at (a0,a1)
	beq a0, zero, not_found #if pixel is black, marker not found
	addi s10, s10, 1	#inc x value
	mv a0, s10
	j b_loop

end_bf:
	mv a0, a3		#set a0 and a1 to previously saved values 
	mv a1, t5
	srli s6, s6, 1		#divide width by 2
	mv ra, s7		#move s7 to return register
	ret



go_up:
	mv s7, ra		#save return value in s7
	mv s10, a3		#move saved a3 value to s10
	mv a0, a3		#same for a0
	mv a1, t5		#move saved t5 value to a1
	addi s5, s5, 1		#add 1 to heigth counter
up_loop:
	beq a1, s4, not_found	#if a1 reached top of file, not found
	jal get_pixel		#get color of pixel at a0, a1
	bne a0, zero, not_found	#if a0 is not black, not found
	beq s5, s6, end_up	#if width/height proportions are ok, end up
	mv a0, s10		
	addi a1, a1, 1		#increment row (a1)
	addi s5, s5, 1		#increment heigth counter
	j up_loop
	
end_up:
	addi a1, a1, 1		#increment row
	mv a0, s10
	jal get_pixel		#get value of pixel at a0,a1
	beq a0, zero, not_found	#if its black, not found
	mv a5, a1		#save a1 value to a5
	j right_frame

right_frame:
	mv a1, t5		#load saved t5 value into a1
	addi s10, s10, 1	#increment x coordinate by 1
	mv a0, s10		
	
rf_loop:
	jal get_pixel		#get color of pixel at a0,a1
	beq a5, a1, end_rf
	beq a0, zero, not_found
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
	slli s6, s6, 1 #bottom length
	sub s5, s10, s6 #main_X - bl
	addi s5, s5, 1 #correction
	mv a6, s5
	mv a0, s10
left_loop:
	ble a0, s5, not_found
	jal get_pixel
	bne a0, zero, up_right_frame
	addi s10, s10, -1
	mv a0, s10
	j left_loop
	
up_right_frame:
	mv s6, s10
	mv s10, a3
	addi a1, a1, 1
	mv a0, s10
	
urf_loop:
	beq s10, s6 go_down
	jal get_pixel
	beq a0, zero, not_found
	addi s10, s10, -1
	mv a0, s10
	j urf_loop
	
	
	

go_down:
	addi s10, s10, 1
	mv a0, s10
	addi a1, a1, -1
	mv s9, a1
	sub s5, a3, s10   #arm width
	add a4, t5, s5
down_loop:
	beq a1, a4, up_left_frame
	jal get_pixel
	bne a0, zero, not_found
	mv a0, s10
	addi a1, a1, -1
	j down_loop
	
	#blt a1, t5, not_found
	#jal get_pixel
	#beq a0, zero, not_found
	#addi a1, a1, -1
	#mv a0, s10
	#j down_loop
	
up_left_frame:
	addi s10, s10, -1
	mv a1, s9
	mv a0, s10
ulf_loop:
	beq a1, a4, left_again
	jal get_pixel
	beq a0, zero, not_found
	mv a0, s10
	addi a1, a1, -1
	j ulf_loop
	
left_again:
	mv a0, s10
	mv s9, s10
la_loop:
	blt a0, a6, la_frame
	jal get_pixel
	bne a0, zero, not_found
	addi s10, s10, -1
	mv a0, s10
	j la_loop
	
la_frame:
	addi a1, a1, 1
	mv s10, s9
	mv a0, s10
laf_loop:
	blt a0, a6, down_again
	jal get_pixel
	beq a0, zero, not_found
	addi s10, s10, -1
	mv a0, s10
	j laf_loop
	
down_again:
	addi s10, s10, 1
	addi a1, a1, -1
	mv s9, a1
	mv a0, s10
da_loop:
	blt a1, t5, da_frame
	jal get_pixel
	bne a0, zero, not_found
	addi a1, a1, -1
	mv a0, s10
	j da_loop
	
da_frame:
	mv a1, s9
	addi s10, s10, -1
	mv a0, s10
daf_loop:
	blt a1, t5, marker_found
	jal get_pixel
	beq a0, zero, not_found
	addi a1, a1, -1
	mv a0, s10
	j daf_loop

marker_found:
	sub s0, s4, t5
	addi s0, s0, -1
	li a7, 4
	li a1, 80
	la a0, msg
	ecall
	li a7, 1
	mv a0, a3
	ecall
	li a7, 11
	li a0, ','
	ecall
	li a7, 1
	mv a0, s0
	ecall
	j not_found


not_found:
	mv s10, a3
	addi s10, s10, 1
	mv a1, t5
	li s6, 0
	li s5, 0
	j black_loop_row
	
		
	
get_pixel:
#description: 
#	returns color of specified pixel
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - 0RGB - pixel color

	#pixel address calculation
	li t4,BYTES_PER_ROW
	mul t1, a1, t4 		#t1= y*BYTES_PER_ROW
	mv t3, a0		
	slli a0, a0, 1
	add t3, t3, a0		#$t3= 3*x
	add t1, t1, t3		#$t1 = 3x + y*BYTES_PER_ROW
	add t2, s2, t1	#pixel address 
	
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
