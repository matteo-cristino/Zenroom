# This Makefile can be used with GNU Make or BSD Make

LIB := libargon2.a
OBJECTS := thread.o  ref.o  opt.o  genkat.o  encoding.o  core.o  argon2.o
RM ?= rm
ifneq(,$(findstring javascript,$(MAKECMDGOALS)))
CFLAGS += -msse -msse2 -msimd128
endif
CFLAGS := ${CFLAGS} -I.. -I.

all: $(LIB)

%.o: %.c
	$(CC) $(CFLAGS) -fPIC -c -o $@ $<

$(LIB): $(OBJECTS)
	$(AR) -r $@ $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(LIB)
