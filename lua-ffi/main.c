
#if defined(_WIN32)

	__declspec(dllexport)
	int get_magenta(void){
		return 3;
	}

#else

	extern int name_to_color(const unsigned char *name);

	int get_magenta(void)
	{
		return name_to_color((unsigned char *)"Magenta");
	}

#endif
