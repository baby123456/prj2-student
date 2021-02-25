

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <assert.h>
#include "xvcserver.h"
#include "xvc_ioctl.h"
#include <unistd.h>

#include <sys/time.h>

#ifndef _WINDOWS

#include <sys/ioctl.h>
 #include <errno.h>
#endif


#define PHY_BASE_ADDR        0x90000000
#define LENGTH_REG_OFFSET    0x00   //0x00
#define TMS_REG_OFFSET       0x01   //0x04
#define TDI_REG_OFFSET       0x02   //0x08
#define TDO_REG_OFFSET       0x03   //0x0C
#define CONTROL_REG_OFFSET   0x04   //0x10


static unsigned int *map_base_word;


static int xil_xvc_shift_bits(int32_t tms_bits, int32_t tdi_bits, int32_t *tdo_bits) {
	int count = 100;

	*(map_base_word + TMS_REG_OFFSET) = tms_bits;
    *(map_base_word + TDI_REG_OFFSET) = tdi_bits;

	while (count) {
	    count--;
	}
    count = 100;
    *(map_base_word + CONTROL_REG_OFFSET) = 0x01;

	while (count) {

		if (((*(map_base_word + CONTROL_REG_OFFSET)) & 0x01) == 0)	{

			break;
		}
		count--;
	}
	if (count == 0)	{
	    printf("XVC bar transaction timed out\n");
		return -ETIMEDOUT;
	}

	*tdo_bits = *(map_base_word + TDO_REG_OFFSET);

	return 0;
}


ssize_t xil_xvc_ioctl(struct xil_xvc_ioc *xvc_obj) {
	int32_t num_bits;
	int32_t current_bit;
	int status = 0;
	
	num_bits = xvc_obj->length;

	if (num_bits >= 32) {
	    *(map_base_word + LENGTH_REG_OFFSET) = 0x20;
	}

	current_bit = 0;
	while (current_bit < num_bits) {
		int shift_num_bytes;
		int shift_num_bits = 32;

		int32_t tms_store = 0;
		int32_t tdi_store = 0;
		int32_t tdo_store = 0;

		if (num_bits - current_bit < shift_num_bits) {
			shift_num_bits = num_bits - current_bit;
			*(map_base_word + LENGTH_REG_OFFSET) = shift_num_bits;
		}

		// Copy only the remaining number of bytes out of user-space
		shift_num_bytes = (shift_num_bits + 7) / 8;
		
	
		memcpy(&tms_store, xvc_obj->tms_buf + (current_bit / 8), shift_num_bytes);
		memcpy(&tdi_store, xvc_obj->tdi_buf + (current_bit / 8), shift_num_bytes);

		// Shift data out and copy to output buffer

		status = xil_xvc_shift_bits(tms_store, tdi_store, &tdo_store);

		if (status) {
			return -1;
		}

		memcpy(xvc_obj->tdo_buf + (current_bit / 8), &tdo_store, shift_num_bytes);

		current_bit += shift_num_bits;
	}
	
	return status;
}


static void set_tck(unsigned long nsperiod, unsigned long *result) {
    *result = nsperiod;
}

static void shift_tms_tdi(
    unsigned long bitcount,
    unsigned char *tms_buf,
    unsigned char *tdi_buf,
    unsigned char *tdo_buf) {


    struct xil_xvc_ioc xvc_ioc;

    xvc_ioc.opcode = 0x01; // 0x01 for normal, 0x02 for bypass
    xvc_ioc.length = bitcount;
    xvc_ioc.tms_buf = tms_buf;
    xvc_ioc.tdi_buf = tdi_buf;
    xvc_ioc.tdo_buf = tdo_buf;

    int ret = xil_xvc_ioctl(&xvc_ioc); 
    if (ret < 0)
    {
        int errsv = errno;
        printf("IOC Error %d\n", errsv);
    }



}

XvcServerHandlers handlers = {
    set_tck,
    shift_tms_tdi,
    NULL,
    NULL,
    NULL,
    NULL
};

int main() {
    const char * port = "2542";
    int fd;
	unsigned char *map_base;
    fd = open("/dev/mem", O_RDWR|O_SYNC);  
	if (fd == -1)  
	{  
		return (-1);  
	} 
	
	map_base = mmap(NULL, 0x20, PROT_READ|PROT_WRITE, MAP_SHARED, fd, PHY_BASE_ADDR);
	
	if (map_base == NULL) 
	{  
		printf("NULL pointer!\n"); 
		return -1;
	}  

	map_base_word = (unsigned int *)map_base;
	
    return xvcserver_start(port, &handlers);
	
	munmap(map_base,0x20);
	close(fd);
}
