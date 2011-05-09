// #include <stdlib.h>

// This is a demo programm bla

float questionmark (int x, int y);

int main (void){
	
	int variable_1;
	int variable_2;
	float variable_3;
	
	variable_1 = 1;
	variable_2 = 2;
	
	while (variable_1 <= 10 && 1){
	/*this loop runs how many times?*/
		
		variable_3 = questionmark (variable_1, variable_2);
			
		variable_2 = ++variable_1;
		variable_2 = variable_2 << 2;
	}
	// what is the value of variable_2
	
	if(! variable_3){
		return 0;
	}else{
		return 1;
	}
}

float questionmark (int x, int y){
//what makes this function

	float result;
	
	do{
		if (y/x){
			result = 1.0;
		}
		--y;
	}while( y < x || 0);
	
	return result;
}



