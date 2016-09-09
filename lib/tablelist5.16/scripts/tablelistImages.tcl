#==============================================================================
# Contains procedures that create various bitmap and photo images.  The
# argument w specifies a canvas displaying a sort arrow, while the argument win
# stands for a tablelist widget.
#
# Copyright (c) 2006-2016  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#------------------------------------------------------------------------------
# tablelist::flat5x3Arrows
#------------------------------------------------------------------------------
proc tablelist::flat5x3Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp5x3_width 5
#define triangleUp5x3_height 3
static unsigned char triangleUp5x3_bits[] = {
   0x04, 0x0e, 0x1f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn5x3_width 5
#define triangleDn5x3_height 3
static unsigned char triangleDn5x3_bits[] = {
   0x1f, 0x0e, 0x04};
"
}

#------------------------------------------------------------------------------
# tablelist::flat5x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flat5x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp5x4_width 5
#define triangleUp5x4_height 4
static unsigned char triangleUp5x4_bits[] = {
   0x04, 0x0e, 0x1f, 0x1f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn5x4_width 5
#define triangleDn5x4_height 4
static unsigned char triangleDn5x4_bits[] = {
   0x1f, 0x1f, 0x0e, 0x04};
"
}

#------------------------------------------------------------------------------
# tablelist::flat6x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flat6x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp6x4_width 6
#define triangleUp6x4_height 4
static unsigned char triangleUp6x4_bits[] = {
   0x0c, 0x1e, 0x3f, 0x3f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn6x4_width 6
#define triangleDn6x4_height 4
static unsigned char triangleDn7x4_bits[] = {
   0x3f, 0x3f, 0x1e, 0x0c};
"
}

#------------------------------------------------------------------------------
# tablelist::flat7x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flat7x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x4_width 7
#define triangleUp7x4_height 4
static unsigned char triangleUp7x4_bits[] = {
   0x08, 0x1c, 0x3e, 0x7f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x4_width 7
#define triangleDn7x4_height 4
static unsigned char triangleDn7x4_bits[] = {
   0x7f, 0x3e, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flat7x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flat7x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x5_width 7
#define triangleUp7x5_height 5
static unsigned char triangleUp7x5_bits[] = {
   0x08, 0x1c, 0x3e, 0x7f, 0x7f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x5_width 7
#define triangleDn7x5_height 5
static unsigned char triangleDn7x5_bits[] = {
   0x7f, 0x7f, 0x3e, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flat7x7Arrows
#------------------------------------------------------------------------------
proc tablelist::flat7x7Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x7_width 7
#define triangleUp7x7_height 7
static unsigned char triangleUp7x7_bits[] = {
   0x08, 0x1c, 0x1c, 0x3e, 0x3e, 0x7f, 0x7f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x7_width 7
#define triangleDn7x7_height 7
static unsigned char triangleDn7x7_bits[] = {
   0x7f, 0x7f, 0x3e, 0x3e, 0x1c, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flat8x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flat8x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp8x4_width 8
#define triangleUp8x4_height 4
static unsigned char triangleUp8x4_bits[] = {
   0x18, 0x3c, 0x7e, 0xff};
"
    image create bitmap triangleDn$w -data "
#define triangleDn8x4_width 8
#define triangleDn8x4_height 4
static unsigned char triangleDn8x4_bits[] = {
   0xff, 0x7e, 0x3c, 0x18};
"
}

#------------------------------------------------------------------------------
# tablelist::flat8x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flat8x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp8x5_width 8
#define triangleUp8x5_height 5
static unsigned char triangleUp8x5_bits[] = {
   0x18, 0x3c, 0x7e, 0xff, 0xff};
"
    image create bitmap triangleDn$w -data "
#define triangleDn8x5_width 8
#define triangleDn8x5_height 5
static unsigned char triangleDn8x5_bits[] = {
   0xff, 0xff, 0x7e, 0x3c, 0x18};
"
}

#------------------------------------------------------------------------------
# tablelist::flat9x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flat9x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x5_width 9
#define triangleUp9x5_height 5
static unsigned char triangleUp9x5_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x7c, 0x00, 0xfe, 0x00, 0xff, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x5_width 9
#define triangleDn9x5_height 5
static unsigned char triangleDn9x5_bits[] = {
   0xff, 0x01, 0xfe, 0x00, 0x7c, 0x00, 0x38, 0x00, 0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flat9x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flat9x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x6_width 9
#define triangleUp9x6_height 6
static unsigned char triangleUp9x6_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x7c, 0x00, 0xfe, 0x00, 0xff, 0x01, 0xff, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x6_width 9
#define triangleDn9x6_height 6
static unsigned char triangleDn9x6_bits[] = {
   0xff, 0x01, 0xff, 0x01, 0xfe, 0x00, 0x7c, 0x00, 0x38, 0x00, 0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flat11x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flat11x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp11x6_width 11
#define triangleUp11x6_height 6
static unsigned char triangleUp11x6_bits[] = {
   0x20, 0x00, 0x70, 0x00, 0xf8, 0x00, 0xfc, 0x01, 0xfe, 0x03, 0xff, 0x07};
"
    image create bitmap triangleDn$w -data "
#define triangleDn11x6_width 11
#define triangleDn11x6_height 6
static unsigned char triangleDn11x6_bits[] = {
   0xff, 0x07, 0xfe, 0x03, 0xfc, 0x01, 0xf8, 0x00, 0x70, 0x00, 0x20, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flat15x8Arrows
#------------------------------------------------------------------------------
proc tablelist::flat15x8Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp15x8_width 15
#define triangleUp15x8_height 8
static unsigned char triangleUp15x8_bits[] = {
   0x80, 0x00, 0xc0, 0x01, 0xe0, 0x03, 0xf0, 0x07, 0xf8, 0x0f, 0xfc, 0x1f,
   0xfe, 0x3f, 0xff, 0x7f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn15x8_width 15
#define triangleDn15x8_height 8
static unsigned char triangleDn15x8_bits[] = {
   0xff, 0x7f, 0xfe, 0x3f, 0xfc, 0x1f, 0xf8, 0x0f, 0xf0, 0x07, 0xe0, 0x03,
   0xc0, 0x01, 0x80, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle7x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle7x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x4_width 7
#define triangleUp7x4_height 4
static unsigned char triangleUp7x4_bits[] = {
   0x08, 0x1c, 0x36, 0x63};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x4_width 7
#define triangleDn7x4_height 4
static unsigned char triangleDn7x4_bits[] = {
   0x63, 0x36, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle7x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle7x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x5_width 7
#define triangleUp7x5_height 5
static unsigned char triangleUp7x5_bits[] = {
   0x08, 0x1c, 0x3e, 0x77, 0x63};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x5_width 7
#define triangleDn7x5_height 5
static unsigned char triangleDn7x5_bits[] = {
   0x63, 0x77, 0x3e, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle9x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle9x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x5_width 9
#define triangleUp9x5_height 5
static unsigned char triangleUp9x5_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x6c, 0x00, 0xc6, 0x00, 0x83, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x5_width 9
#define triangleDn9x5_height 5
static unsigned char triangleDn9x5_bits[] = {
   0x83, 0x01, 0xc6, 0x00, 0x6c, 0x00, 0x38, 0x00, 0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle9x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle9x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x6_width 9
#define triangleUp9x6_height 6
static unsigned char triangleUp9x6_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x7c, 0x00, 0xee, 0x00, 0xc7, 0x01, 0x83, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x6_width 9
#define triangleDn9x6_height 6
static unsigned char triangleDn9x6_bits[] = {
   0x83, 0x01, 0xc7, 0x01, 0xee, 0x00, 0x7c, 0x00, 0x38, 0x00, 0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle9x7Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle9x7Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x7_width 9
#define triangleUp9x7_height 7
static unsigned char triangleUp9x7_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x7c, 0x00, 0xfe, 0x00, 0xef, 0x01, 0xc7, 0x01,
   0x83, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x7_width 9
#define triangleDn9x7_height 7
static unsigned char triangleDn9x7_bits[] = {
   0x83, 0x01, 0xc7, 0x01, 0xef, 0x01, 0xfe, 0x00, 0x7c, 0x00, 0x38, 0x00,
   0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle10x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle10x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp10x6_width 10
#define triangleUp10x6_height 6
static unsigned char triangleUp10x6_bits[] = {
   0x30, 0x00, 0x78, 0x00, 0xfc, 0x00, 0xce, 0x01, 0x87, 0x03, 0x03, 0x03};
"
    image create bitmap triangleDn$w -data "
#define triangleDn10x6_width 10
#define triangleDn10x6_height 6
static unsigned char triangleDn10x6_bits[] = {
   0x03, 0x03, 0x87, 0x03, 0xce, 0x01, 0xfc, 0x00, 0x78, 0x00, 0x30, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle10x7Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle10x7Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp10x7_width 10
#define triangleUp10x7_height 7
static unsigned char triangleUp10x7_bits[] = {
   0x30, 0x00, 0x78, 0x00, 0xfc, 0x00, 0xfe, 0x01, 0xcf, 0x03, 0x87, 0x03,
   0x03, 0x03};
"
    image create bitmap triangleDn$w -data "
#define triangleDn10x7_width 10
#define triangleDn10x7_height 7
static unsigned char triangleDn10x6_bits[] = {
   0x03, 0x03, 0x87, 0x03, 0xcf, 0x03, 0xfe, 0x01, 0xfc, 0x00, 0x78, 0x00,
   0x30, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle11x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle11x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp11x6_width 11
#define triangleUp11x6_height 6
static unsigned char triangleUp11x6_bits[] = {
   0x20, 0x00, 0x70, 0x00, 0xd8, 0x00, 0x8c, 0x01, 0x06, 0x03, 0x03, 0x06};
"
    image create bitmap triangleDn$w -data "
#define triangleDn11x6_width 11
#define triangleDn11x6_height 6
static unsigned char triangleDn11x6_bits[] = {
   0x03, 0x06, 0x06, 0x03, 0x8c, 0x01, 0xd8, 0x00, 0x70, 0x00, 0x20, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle15x8Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle15x8Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp15x8_width 15
#define triangleUp15x8_height 8
static unsigned char triangleUp15x8_bits[] = {
   0x80, 0x00, 0xc0, 0x01, 0x60, 0x03, 0x30, 0x06, 0x18, 0x0c, 0x0c, 0x18,
   0x06, 0x30, 0x03, 0x60};
"
    image create bitmap triangleDn$w -data "
#define triangleDn15x8_width 15
#define triangleDn15x8_height 8
static unsigned char triangleDn15x8_bits[] = {
   0x03, 0x60, 0x06, 0x30, 0x0c, 0x18, 0x18, 0x0c, 0x30, 0x06, 0x60, 0x03,
   0xc0, 0x01, 0x80, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::photo7x4Arrows
#------------------------------------------------------------------------------
proc tablelist::photo7x4Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
R0lGODlhBwAEAIQRAAAAADxZbDxeckNfb0BidF6IoWGWtlabwIexxZq2xYbI65HL7LXd8rri9MPk
9cTj9Mrm9f///////////////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAAHAAQAAAUS4CcSYikcRRkYypJ8A9IwD+SEADs=
"
    triangleDn$w put "
R0lGODlhBwAEAIQQAAAAADxeclKLq2KauWes03CpxnKrynOy2IO62ZXG4JrH4JrL5pnQ7qbY87Pb
8cTj9P///////////////////////////////////////////////////////////////yH5BAEK
AAAALAAAAAAHAAQAAAUSYDAUBpIogHAwzgO8ROO+70KHADs=
"
}

#------------------------------------------------------------------------------
# tablelist::photo7x7Arrows
#------------------------------------------------------------------------------
proc tablelist::photo7x7Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAACXBIWXMAAA7DAAAOwwHHb6hk
AAAAGnRFWHRTb2Z0d2FyZQBQYWludC5ORVQgdjMuNS4xMDD0cqEAAABCSURBVBhXXY4BCgAgCAP9
T//R9/Ryc+ZEHCyb40CB3D1n6OAZuQOKi9klPhUsjNJ6VwUp+tOLopOGNkXncToWw6IPjiowJNyp
gu8AAAAASUVORK5CYII=
"
    triangleDn$w put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwwAADsMBx2+oZAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAP0lE
QVQYV22LgQ0AIAjD9g//yD1ejoBoFpRkISsUPsMzPwkOIcARmJlvKMGIJq9jt+Uem51Wscfe1hkq
8VAdWKBfMCRjQcZZAAAAAElFTkSuQmCC
"
}

#------------------------------------------------------------------------------
# tablelist::photo9x5Arrows
#------------------------------------------------------------------------------
proc tablelist::photo9x5Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
R0lGODlhCQAFAIQTAAAAADxeckBidGaJmlabwG6mw4exxZy9z4bI647M7JvS76HV8KjX8a3a8rPc
8rLe87jf9Lzh9MPk9f///////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAAJAAUAAAUZ4Cd+wWgGhGCSBKIMY1AkSwMdpPEwTiT9IQA7
"
    triangleDn$w put "
R0lGODlhCQAFAIQSAAAAADxeck90imuUrGKauW2jwWes036xzXOy2IO83YO83o++2JrH4JrK5rPZ
7rPZ77TZ7sTj9P///////////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAAJAAUAAAUaYECMxbEwzCcgSNJA0ScPSuPEsmw8eC43vhAAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::photo11x6Arrows
#------------------------------------------------------------------------------
proc tablelist::photo11x6Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
R0lGODlhCwAGAKUjAAAAADJdfDJefDFefjRffDhhfC9njDNrjThtjj5xkUJykWuXs2Ogw2ukxHKp
yHusyZrD2o7M7JfQ7qDE2qfH2arJ2aPQ6aLU76Td+6/h/bDi/rrj+bjm/rrn/8Pm+sLr/8Ps/8ro
+szu////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAALAAYAAAYqwJ9Q
WBgahQTF4ohMPCyQYwDhuHA2k6Hg0JBkOh8P5TcwMCIYTQckClWCADs=
"
    triangleDn$w put "
R0lGODlhCwAGAKUkAAAAADl1ml+DnlaRtWGZu2ievXaet2+gvXekvmKfw32owXu314Kqwoiswoey
yo21zIa+3JC2zZ26y5DB3ZjG34fE5ZHJ55/J4ZrN6KTC1KjN4qLb+azf+rrV5rDi/rrn/7/m+8Ps
/8vu/9Pw////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAALAAYAAAYqQEFg
QCgcEApGQ/IzJBaQCeWi6fyujsrG8wmNruCHhfMRgc8RDOjMzrCDADs=
"
}

#------------------------------------------------------------------------------
# tablelist::photo15x8Arrows
#------------------------------------------------------------------------------
proc tablelist::photo15x8Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
R0lGODlhDwAIAKU/AAAAAB1YfjJefy1pjjVmhjJrjzppiD1qiTVtkTpwkTxwkT18oUFsikRuilKP
s16Rr1aStFyUtWeHnGKKo2CWtXGhvV6dwnOy1Ha02Hu01YKovommuI2xxIC314S31JGyx5W1x5S3
zJi2yJG915nE2p/F24fD44/I5o7K65bF4JbN7ZjM6J/P6Z3Q7Z7X9abJ3anN4KfS6q/U6azV66zX
76fa9qzb9and+bLb8Lne8rHg+rLi+7fi+bnk+73l+v///yH5BAEKAD8ALAAAAAAPAAgAAAZJwJ9w
+JMQj8QGYYI8NhSPiqYpZCQontSI0zwgIp2WjUb6HA8FSEZV0/FwJdDQMHBcUK7brufLvUQ/AgEL
FhgmJyssMTMyMCEbQQA7
"
    triangleDn$w put "
R0lGODlhDwAIAKU/AAAAACdjiUBtjkKBpkaGqlWFpVaUuFyav2SVtGGdv2Cew2ehwm2jw26tz3Ok
wXOmw3amwnuow3ioxH6pw3Gv0nSz13iz03611ICsxYOux4mtwomxyI2yyIK00oa41Yy815KvwZm5
zJO+2JjC2Z/D2J7E2obC4o/I5o3J6pTM65jM6J/P6ZzP657X9avH2anP5afS6q7U6azV66fa9qnZ
9Knd+bjV5rrc8bHg+rLi+7fi+b/g8rnk+7zl+sXh8v///yH5BAEKAD8ALAAAAAAPAAgAAAZIQEFg
YEgsGA8JJrPhaEC/AkHRsFw8H9GoRHL9vohDxXRSrWCymO3LdlBQrVqO1/Ox7xBLaobT7e6AERcs
NDeAhxMdL4eMIYxBADs=
"
}

#------------------------------------------------------------------------------
# tablelist::sunken8x7Arrows
#------------------------------------------------------------------------------
proc tablelist::sunken8x7Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp8x7_width 8
#define triangleUp8x7_height 7
static unsigned char triangleUp8x7_bits[] = {
   0x18, 0x3c, 0x3c, 0x7e, 0x7e, 0xff, 0xff};
"
    image create bitmap darkLineUp$w -data "
#define darkLineUp8x7_width 8
#define darkLineUp8x7_height 7
static unsigned char darkLineUp8x7_bits[] = {
   0x08, 0x0c, 0x04, 0x06, 0x02, 0x03, 0x00};
"
    image create bitmap lightLineUp$w -data "
#define lightLineUp8x7_width 8
#define lightLineUp8x7_height 7
static unsigned char lightLineUp8x7_bits[] = {
   0x10, 0x30, 0x20, 0x60, 0x40, 0xc0, 0xff};
"
    image create bitmap triangleDn$w -data "
#define triangleDn8x7_width 8
#define triangleDn8x7_height 7
static unsigned char triangleDn8x7_bits[] = {
   0xff, 0xff, 0x7e, 0x7e, 0x3c, 0x3c, 0x18};
"
    image create bitmap darkLineDn$w -data "
#define darkLineDn8x7_width 8
#define darkLineDn8x7_height 7
static unsigned char darkLineDn8x7_bits[] = {
   0xff, 0x03, 0x02, 0x06, 0x04, 0x0c, 0x08};
"
    image create bitmap lightLineDn$w -data "
#define lightLineDn8x7_width 8
#define lightLineDn8x7_height 7
static unsigned char lightLineDn8x7_bits[] = {
   0x00, 0xc0, 0x40, 0x60, 0x20, 0x30, 0x10};
"
}

#------------------------------------------------------------------------------
# tablelist::sunken10x9Arrows
#------------------------------------------------------------------------------
proc tablelist::sunken10x9Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp10x9_width 10
#define triangleUp10x9_height 9
static unsigned char triangleUp10x9_bits[] = {
   0x30, 0x00, 0x78, 0x00, 0x78, 0x00, 0xfc, 0x00, 0xfc, 0x00, 0xfe, 0x01,
   0xfe, 0x01, 0xff, 0x03, 0xff, 0x03};
"
    image create bitmap darkLineUp$w -data "
#define darkLineUp10x9_width 10
#define darkLineUp10x9_height 9
static unsigned char darkLineUp10x9_bits[] = {
   0x10, 0x00, 0x18, 0x00, 0x08, 0x00, 0x0c, 0x00, 0x04, 0x00, 0x06, 0x00,
   0x02, 0x00, 0x03, 0x00, 0x00, 0x00};
"
    image create bitmap lightLineUp$w -data "
#define lightLineUp10x9_width 10
#define lightLineUp10x9_height 9
static unsigned char lightLineUp10x9_bits[] = {
   0x20, 0x00, 0x60, 0x00, 0x40, 0x00, 0xc0, 0x00, 0x80, 0x00, 0x80, 0x01,
   0x00, 0x01, 0x00, 0x03, 0xff, 0x03};
"
    image create bitmap triangleDn$w -data "
#define triangleDn10x9_width 10
#define triangleDn10x9_height 9
static unsigned char triangleDn10x9_bits[] = {
   0xff, 0x03, 0xff, 0x03, 0xfe, 0x01, 0xfe, 0x01, 0xfc, 0x00, 0xfc, 0x00,
   0x78, 0x00, 0x78, 0x00, 0x30, 0x00};
"
    image create bitmap darkLineDn$w -data "
#define darkLineDn10x9_width 10
#define darkLineDn10x9_height 9
static unsigned char darkLineDn10x9_bits[] = {
   0xff, 0x03, 0x03, 0x00, 0x02, 0x00, 0x06, 0x00, 0x04, 0x00, 0x0c, 0x00,
   0x08, 0x00, 0x18, 0x00, 0x10, 0x00};
"
    image create bitmap lightLineDn$w -data "
#define lightLineDn10x9_width 10
#define lightLineDn10x9_height 9
static unsigned char lightLineDn10x9_bits[] = {
   0x00, 0x00, 0x00, 0x03, 0x00, 0x01, 0x80, 0x01, 0x80, 0x00, 0xc0, 0x00,
   0x40, 0x00, 0x60, 0x00, 0x20, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::sunken12x11Arrows
#------------------------------------------------------------------------------
proc tablelist::sunken12x11Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp12x11_width 12
#define triangleUp12x11_height 11
static unsigned char triangleUp12x11_bits[] = {
   0x60, 0x00, 0xf0, 0x00, 0xf0, 0x00, 0xf8, 0x01, 0xf8, 0x01, 0xfc, 0x03,
   0xfc, 0x03, 0xfe, 0x07, 0xfe, 0x07, 0xff, 0x0f, 0xff, 0x0f};
"
    image create bitmap darkLineUp$w -data "
#define darkLineUp12x11_width 12
#define darkLineUp12x11_height 11
static unsigned char darkLineUp12x11_bits[] = {
   0x20, 0x00, 0x30, 0x00, 0x10, 0x00, 0x18, 0x00, 0x08, 0x00, 0x0c, 0x00,
   0x04, 0x00, 0x06, 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00};
"
    image create bitmap lightLineUp$w -data "
#define lightLineUp12x11_width 12
#define lightLineUp12x11_height 11
static unsigned char lightLineUp12x11_bits[] = {
   0x40, 0x00, 0xc0, 0x00, 0x80, 0x00, 0x80, 0x01, 0x00, 0x01, 0x00, 0x03,
   0x00, 0x02, 0x00, 0x06, 0x00, 0x04, 0x00, 0x0c, 0xff, 0x0f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn12x11_width 12
#define triangleDn12x11_height 11
static unsigned char triangleDn12x11_bits[] = {
   0xff, 0x0f, 0xff, 0x0f, 0xfe, 0x07, 0xfe, 0x07, 0xfc, 0x03, 0xfc, 0x03,
   0xf8, 0x01, 0xf8, 0x01, 0xf0, 0x00, 0xf0, 0x00, 0x60, 0x00};
"
    image create bitmap darkLineDn$w -data "
#define darkLineDn12x11_width 12
#define darkLineDn12x11_height 11
static unsigned char darkLineDn12x11_bits[] = {
   0xff, 0x0f, 0x03, 0x00, 0x02, 0x00, 0x06, 0x00, 0x04, 0x00, 0x0c, 0x00,
   0x08, 0x00, 0x18, 0x00, 0x10, 0x00, 0x30, 0x00, 0x20, 0x00};
"
    image create bitmap lightLineDn$w -data "
#define lightLineDn12x11_width 12
#define lightLineDn12x11_height 11
static unsigned char lightLineDn12x11_bits[] = {
   0x00, 0x00, 0x00, 0x0c, 0x00, 0x04, 0x00, 0x06, 0x00, 0x02, 0x00, 0x03,
   0x00, 0x01, 0x80, 0x01, 0x80, 0x00, 0xc0, 0x00, 0x40, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::createSortRankImgs
#------------------------------------------------------------------------------
proc tablelist::createSortRankImgs win {
    image create bitmap sortRank1$win -data "
#define sortRank1_width 4
#define sortRank1_height 6
static unsigned char sortRank1_bits[] = {
   0x04, 0x06, 0x04, 0x04, 0x04, 0x04};
"
    image create bitmap sortRank2$win -data "
#define sortRank2_width 4
#define sortRank2_height 6
static unsigned char sortRank2_bits[] = {
   0x06, 0x09, 0x08, 0x04, 0x02, 0x0f};
"
    image create bitmap sortRank3$win -data "
#define sortRank3_width 4
#define sortRank3_height 6
static unsigned char sortRank3_bits[] = {
   0x0f, 0x08, 0x06, 0x08, 0x09, 0x06};
"
    image create bitmap sortRank4$win -data "
#define sortRank4_width 4
#define sortRank4_height 6
static unsigned char sortRank4_bits[] = {
   0x04, 0x06, 0x05, 0x0f, 0x04, 0x04};
"
    image create bitmap sortRank5$win -data "
#define sortRank5_width 4
#define sortRank5_height 6
static unsigned char sortRank5_bits[] = {
   0x0f, 0x01, 0x07, 0x08, 0x09, 0x06};
"
    image create bitmap sortRank6$win -data "
#define sortRank6_width 4
#define sortRank6_height 6
static unsigned char sortRank6_bits[] = {
   0x06, 0x01, 0x07, 0x09, 0x09, 0x06};
"
    image create bitmap sortRank7$win -data "
#define sortRank7_width 4
#define sortRank7_height 6
static unsigned char sortRank7_bits[] = {
   0x0f, 0x08, 0x04, 0x04, 0x02, 0x02};
"
    image create bitmap sortRank8$win -data "
#define sortRank8_width 4
#define sortRank8_height 6
static unsigned char sortRank8_bits[] = {
   0x06, 0x09, 0x06, 0x09, 0x09, 0x06};
"
    image create bitmap sortRank9$win -data "
#define sortRank9_width 4
#define sortRank9_height 6
static unsigned char sortRank9_bits[] = {
   0x06, 0x09, 0x09, 0x0e, 0x08, 0x06};
"
}

#------------------------------------------------------------------------------
# tablelist::createCheckbuttonImgs
#------------------------------------------------------------------------------
proc tablelist::createCheckbuttonImgs {} {
    variable checkedImg [image create bitmap tablelist_checkedImg -data "
#define checked_width 9
#define checked_height 9
static unsigned char checked_bits[] = {
   0x00, 0x00, 0x80, 0x00, 0xc0, 0x00, 0xe2, 0x00, 0x76, 0x00, 0x3e, 0x00,
   0x1c, 0x00, 0x08, 0x00, 0x00, 0x00};
"]

    variable uncheckedImg [image create bitmap tablelist_uncheckedImg -data "
#define unchecked_width 9
#define unchecked_height 9
static unsigned char unchecked_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
"]
}

#------------------------------------------------------------------------------
# tablelist::adwaitaTreeImgs
#------------------------------------------------------------------------------
proc tablelist::adwaitaTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel
		  collapsedAct expandedAct collapsedSelAct expandedSelAct} {
	variable adwaita_${mode}Img \
		 [image create photo tablelist_adwaita_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_adwaita_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAS0lEQVQoz2NgGCgQRIwiJjS+GgMD
QzipmhgYGBhkCGnEpomVkEYmHOIwjUmkaMILWHCI/2ZgYHjCwMCwklib8GrApQmvBrIjl34AABCG
CT/IZJIxAAAAAElFTkSuQmCC
"
	tablelist_adwaita_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAVUlEQVQoz+3RsQmAMBQG4U/ENVI7
k5M4kSBuJThA6jQ2EUKIoKXgNY8f7qrHD+gQMD1wF+zQI+Yx5l2TsF6BQoo4GmHCVgYqoQ6bwR0B
c76vGD783BOQlRBaIgVX4QAAAABJRU5ErkJggg==
"
	tablelist_adwaita_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAT0lEQVQoz2NgGBDw////WGLUMaHx
df7//59CqiYGBgYGBUIasWliJaSRCYc4TGMRKZrwAhYc4r8ZGBgeMDIyziHWJrwacGnCq4HsyKUf
AADrxRtigikXoAAAAABJRU5ErkJggg==
"
	tablelist_adwaita_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAVElEQVQoz+3RsQ2AMAwF0XORSTIZ
DbuwAg2TMQnF0YRICAulReLq/9wY/gAItQLzwHaNiB0gABqcgJKMD2C7QEcv8AFuKIEpSFOrurQD
46nlw889ASlNI826HLaoAAAAAElFTkSuQmCC
"
	tablelist_adwaita_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAU0lEQVQoz8XRsQ2AMAwEwFO6bAPj
sAOjULID0yDYJi0LBIIRiC9fPlmW+SvTE7Ribg2lSte1YA3lFkwnfUaPJYLCN0HBhuEuKtgxRjZd
gtee+10OdDMKiEMkR3cAAAAASUVORK5CYII=
"
	tablelist_adwaita_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAWUlEQVQoz+3RoQ2AQBAF0UfAUM/V
QCsIBAXRz0kEVdDCScxegjgBkoRxP5kxu/yADgnbA3fGDj3OGBOGhlyw1KBGIjwaYcF6D1ok5JBy
7EekiNLbA40ffu4FEEUOYdYQ3mYAAAAASUVORK5CYII=
"
	tablelist_adwaita_collapsedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAPUlEQVQoz2NgGBDw////deRo+v//
//+d5Gj6TJLG/whAvMb/qODb////L2JTx0SN0CPbeWQFxE7aRy5NAQBViGDybBLtUAAAAABJRU5E
rkJggg==
"
	tablelist_adwaita_expandedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAMUlEQVQoz2NgGAUQ8P//f/v/xAF7
bBq/4VD8DUMDAY24NeDQSFgDFj/akxo4PEM4bgEyPobIeZ962wAAAABJRU5ErkJggg==
"
    } else {
	tablelist_adwaita_collapsedImg put "
R0lGODlhDQAOAMIGAAAAAIeHh4yMjJ2dnaioqK2trf///////yH5BAEKAAcALAAAAAANAA4AAAMd
eLrc/qdAFshUQdgZ8n5dNkChMIIep13VFbkwnAAAOw==
"
	tablelist_adwaita_expandedImg put "
R0lGODlhDQAOAKEDAAAAAIeHh4yMjP///yH5BAEKAAMALAAAAAANAA4AAAIWnI+py+0fopRJzCCW
jZnZ3gTPSJZNAQA7
"
	tablelist_adwaita_collapsedSelImg put "
R0lGODlhDQAOAKECAAAAAMzMzP///////yH5BAEKAAAALAAAAAANAA4AAAIXhI+pC8EY3Gtxxsou
Vlry+4Chl03maRQAOw==
"
	tablelist_adwaita_expandedSelImg put "
R0lGODlhDQAOAKECAAAAAMzMzP///////yH5BAEKAAAALAAAAAANAA4AAAIRhI+py+0fopRpUmXb
1a/73xQAOw==
"
	tablelist_adwaita_collapsedActImg put "
R0lGODlhDQAOAMIHAAAAADIyMjo6Ojs7O1hYWGtra3Nzc////yH5BAEKAAcALAAAAAANAA4AAAMd
eLrc/sdAFspUYdgZ8n5dIBBQOJYep13VFbkwnAAAOw==
"
	tablelist_adwaita_expandedActImg put "
R0lGODlhDQAOAKEDAAAAADIyMjo6Ov///yH5BAEKAAMALAAAAAANAA4AAAIWnI+py+0fopRJzCCW
jZnZ3gTPSJZNAQA7
"
	tablelist_adwaita_collapsedSelActImg put "
R0lGODlhDQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAANAA4AAAIXhI+pC8EY3Gtxxsou
Vlry+4Chl03maRQAOw==
"
	tablelist_adwaita_expandedSelActImg put "
R0lGODlhDQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAANAA4AAAIRhI+py+0fopRpUmXb
1a/73xQAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::ambianceTreeImgs
#------------------------------------------------------------------------------
proc tablelist::ambianceTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable ambiance_${mode}Img \
		 [image create photo tablelist_ambiance_${mode}Img]
    }

    tablelist_ambiance_collapsedImg put "
R0lGODlhEgAQAKUxAAAAADw7N9/Wxd/Wxt/WyODYyeLZyuHazeTdz+Pd0eTd0uXf0+Xf1efg1OXg
1ujh0+jg1Onj1+nj2Ork2O3m3Ozm3e7p4e/q4e7s5u/s6PHs5PHs5fHs5vHu6fPw6vTw6vTw6/bz
7vbz7/b07vb07/b08Pb08fj28/n49Pr59fr59vv5+Pv6+Pr6+vz6+fz7+v39/f//////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAahwJ9w
SCwWD4KkUnkwFjotmHQKa2UKxENmxXK5XmAva4VpCgWmEwqVSqna61NJMBSERKSSyRTYl0gjJHRn
Hx4dHiAgAYkeHh8fgz8CHJQcGhsBGxuVHJECFxcWAaOkAaAXnhUVFKoVAa2tnhMRErUSAbYRExOe
DxC/vwHAEA0PngoIycrLCAuRBwwG0tPUBg5mQgUJBAPd3gMECVhHS+XYQkEAOw==
"
    tablelist_ambiance_expandedImg put "
R0lGODlhEgAQAKUyAAAAADw7N9/Wxd/Wxt/WyODYyeLZyuHazeTdz+Pd0eTd0uXf0+Xf1efg1OXg
1ujh0+jg1Onj1+nj2Ork2O3m3Ozm3e7p4e/q4e7s5u/s6PHs5PHs5fHs5vHu6fPw6vTw6vTw6/bz
7vbz7/b07vb07/b08Pb08fj18fj28/n49Pr59fr59vv5+Pv6+Pr6+vz6+fz7+v39/f//////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAabwJ9w
SCwWD4KkUnkwFjqumHQac2UKxEOG1Xq9YGBvi4VpCgUmVCqlUq3aa1RJMBSERKSSyXTal0gjJHRn
Hx4dHiCJiR4eHx+DPwIckxwaGxwbl5SQAhcXFgGhogGeF5wVFRSoq6wVnBMRErKzshETE5wPELu8
vQ0PnAoIw8TFCAuQBwwGzM3OBg5mQgUJBAPX2AMECVhHS9/SQkEAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::aquaTreeImgs
#------------------------------------------------------------------------------
proc tablelist::aquaTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable aqua_${mode}Img \
		 [image create photo tablelist_aqua_${mode}Img]
    }

    variable pngSupported
    variable winSys
    scan $::tcl_platform(osVersion) "%d" majorOSVersion
    if {[string compare $winSys "aqua"] == 0 && $majorOSVersion > 10} {
	set osVerPost10 1
    } else {
	set osVerPost10 0
    }

    if {$pngSupported} {
	if {$osVerPost10} {
	    tablelist_aqua_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAAOCAYAAADABlfOAAAAhElEQVQ4y2NgGNGAGZtgcXHxQysr
q3vHjx+/SY6hjDgM/Q9lbmNgYMjt7e29R4qhTATkvRgYGK4XFxdXUdOlyOAaAwNDVm9v70FKXYoM
tBgYGA4UFxcHUNPQawwMDA69vb0bCClkIcKwXwwMDI29vb1txNpOyFCyYh+XoY+ghm0a3tkUADMc
JviPkg0NAAAAAElFTkSuQmCC
"
	    tablelist_aqua_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAAOCAYAAADABlfOAAAAh0lEQVQ4y2NgGAXUBozoAsXFxQ8Z
GBjk8Oh51NvbK4/PUCYsYrkEHJJLskuhrt3KwMDghUVqW29vrzchQ5nwuOYXmtgvYlzJwMDAwIxN
8Pjx4++trKz+MTAwOCMJ1/X29m4iK6LQguEqAwODFgMDw7Xe3l5tYmOfiYB8FhpNHVBcXBwwfHMU
AB22HTxODBH0AAAAAElFTkSuQmCC
"
	} else {
	    tablelist_aqua_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAAOCAYAAADABlfOAAAAfUlEQVQ4y2NgGAXooK2t7WFbW5sf
ufoZcRj6H8rcxsDAkFtVVXWPFEOZCMh7MTAwXG9ra6uipkuRwTUGBoasqqqqg5S6FBloMTAwHGhr
awugpqHXGBgYHKqqqjYQUshChGG/GBgYGquqqtqItZ2QoWTFPi5DH0EN2zS8cyQA1kwj4qCn3a0A
AAAASUVORK5CYII=
"
	    tablelist_aqua_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAAOCAYAAADABlfOAAAAfElEQVQ4y2NgGAXUBozoAm1tbQ8Z
GBjk8Oh5VFVVJY/PUCYsYrkEHJJLskuhrt3KwMDghUVqW1VVlTchQ5nwuOYXmtgvYlyJ09Cqqqp7
DAwMjWjCjVBxBrK8jxQMVxkYGLQYGBiuVVVVaRMb+0wE5LPQaOqAtra2gOGbowDBEhsE22H0+QAA
AABJRU5ErkJggg==
"
	}

	tablelist_aqua_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAAOCAYAAADABlfOAAAASUlEQVQ4y2NgGAXo4P///zf////v
SG1DYWDJ////Jaht6P////9/+v//fxa1DYWB0////zeltqEw4DxoXUr1MKVq7FM/nQ5KAACuJ6cJ
Ve1XOwAAAABJRU5ErkJggg==
"
	tablelist_aqua_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAAOCAYAAADABlfOAAAAUUlEQVQ4y2NgGAU0B////7/5Hz+4
SY6hjgQMdSTXtUtwGLiEkiCQ+P///yc0Az/9//9fgtKwzUIzNItakXYaauBpaqYEU6ihptROYs7D
NwMBAJg2pwnAMF20AAAAAElFTkSuQmCC
"
    } else {
	if {$osVerPost10} {
	    tablelist_aqua_collapsedImg put "
R0lGODlhFQAOAMIGAAAAAHNzc3Z2doODg4qKipubm////////yH5BAEKAAcALAAAAAAVAA4AAAMi
eLrc/jDKqQaFIZTbchDc4mVEOHrcWaYZGB7Z9h7WbN9KAgA7
"
	    tablelist_aqua_expandedImg put "
R0lGODlhFQAOAMIGAAAAAHNzc3Z2doODg4qKipubm////////yH5BAEKAAcALAAAAAAVAA4AAAMg
eLrc/jDKSeUIOIdRda5H4RXgIWRCqXzqQQREu8p0LScAOw==
"
	} else {
	    tablelist_aqua_collapsedImg put "
R0lGODlhFQAOAMIGAAAAAIaGhoiIiJSUlJmZmampqf///////yH5BAEKAAcALAAAAAAVAA4AAAMi
eLrc/jDKqQaFIZTbchDc4mVEOHrcWaYZGB7Z9h7WbN9KAgA7
"
	    tablelist_aqua_expandedImg put "
R0lGODlhFQAOAMIGAAAAAIaGhoiIiJSUlJmZmampqf///////yH5BAEKAAcALAAAAAAVAA4AAAMg
eLrc/jDKSeUIOIdRda5H4RXgIWRCqXzqQQREu8p0LScAOw==
"
	}

	tablelist_aqua_collapsedSelImg put "
R0lGODlhFQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAVAA4AAAIchI+py+1vAmShzlTt
jVnPnl2gJIYbYJ7kybZIAQA7
"
	tablelist_aqua_expandedSelImg put "
R0lGODlhFQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAVAA4AAAIahI+py+0PXZiUxmov
DtHgfmQgII7ciKYqUgAAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::baghiraTreeImgs
#------------------------------------------------------------------------------
proc tablelist::baghiraTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable baghira_${mode}Img \
		 [image create photo tablelist_baghira_${mode}Img]
    }

    tablelist_baghira_collapsedImg put "
R0lGODlhEAAOAIABAAAAAP///yH5BAEKAAEALAAAAAAQAA4AAAIUjI+py+1/AIxygmtvdTrPsH3i
6BQAOw==
"
    tablelist_baghira_expandedImg put "
R0lGODlhEAAOAIABAAAAAP///yH5BAEKAAEALAAAAAAQAA4AAAITjI+py+0PIwO0Amfvq1LLD4ZN
AQA7
"
}

#------------------------------------------------------------------------------
# tablelist::bicolor1TreeImgs
#------------------------------------------------------------------------------
proc tablelist::bicolor1TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable bicolor1_${mode}Img \
		 [image create photo tablelist_bicolor1_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_bicolor1_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAYAAACALL/6AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwYtcCg47AAAACpJREFUGNNjYKAA1BOjiIlUTUyk
2sREqvOYSPUTPg2NpGhoJMVJjVSNBwD8+gSMwdvvHwAAAABJRU5ErkJggg==
"
	tablelist_bicolor1_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAYAAACALL/6AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwkTNtE5iAAAAC9JREFUGNNjYBh0gJGBgaGeCHWN
yBoYCGhqRLeBAY+mRmxOYsChqZFYf9UPbLACACL9BIS+a6kZAAAAAElFTkSuQmCC
"
    } else {
	tablelist_bicolor1_collapsedImg put "
R0lGODlhDAAKAIABAH9/f////yH5BAEKAAEALAAAAAAMAAoAAAIUjI8IybB83INypmqjhGFzxxkZ
UgAAOw==
"
	tablelist_bicolor1_expandedImg put "
R0lGODlhDAAKAIABAH9/f////yH5BAEKAAEALAAAAAAMAAoAAAIQjI+py+D/EIxpNscMyLyHAgA7
"
    }

    tablelist_bicolor1_collapsedSelImg put "
R0lGODlhDAAKAIAAAP///////yH5BAEKAAEALAAAAAAMAAoAAAIUjI8IybB83INypmqjhGFzxxkZ
UgAAOw==
"
    tablelist_bicolor1_expandedSelImg put "
R0lGODlhDAAKAIAAAP///////yH5BAEKAAEALAAAAAAMAAoAAAIQjI+py+D/EIxpNscMyLyHAgA7
"
}

#------------------------------------------------------------------------------
# tablelist::bicolor2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::bicolor2TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable bicolor2_${mode}Img \
		 [image create photo tablelist_bicolor2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_bicolor2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAMCAYAAABSgIzaAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI    
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwwFv3J4nAAAADJJREFUKM9jYKASaCJWIRO5mpnI    
tZmJXGczketnJnIDjBiNdeRorCPHqXXkBE4dzVIOAPKWBZkKDbb3AAAAAElFTkSuQmCC
"
	tablelist_bicolor2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAMCAYAAABSgIzaAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEw4I8/VmowAAADZJREFUKM9jYBgygJGBgaGeBPWN
yBoZiNTciG4jAxGaG7E5lYGA5kZcfmTAo7mR1ECrZxg+AAC4iAWFJSdDXQAAAABJRU5ErkJggg==
"
    } else {
	tablelist_bicolor2_collapsedImg put "
R0lGODlhDgAMAIABAH9/f////yH5BAEKAAEALAAAAAAOAAwAAAIXjI9poA3c0IMxTOpuvS/yPVVW
J5KlWAAAOw==
"
	tablelist_bicolor2_expandedImg put "
R0lGODlhDgAMAIABAH9/f////yH5BAEKAAEALAAAAAAOAAwAAAIUjI+pywoPI0AyuspkC3Cb6YWi
WAAAOw==
"
    }

    tablelist_bicolor2_collapsedSelImg put "
R0lGODlhDgAMAIAAAP///////yH5BAEKAAEALAAAAAAOAAwAAAIXjI9poA3c0IMxTOpuvS/yPVVW
J5KlWAAAOw==
"
    tablelist_bicolor2_expandedSelImg put "
R0lGODlhDgAMAIAAAP///////yH5BAEKAAEALAAAAAAOAAwAAAIUjI+pywoPI0AyuspkC3Cb6YWi
WAAAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::bicolor3TreeImgs
#------------------------------------------------------------------------------
proc tablelist::bicolor3TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable bicolor3_${mode}Img \
		 [image create photo tablelist_bicolor3_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_bicolor3_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExAQNNjBKgAAADtJREFUKM9jYKABqCdHExM1DGKi
houYqOE1JmqEERM1ApuJGrFGrCGNlBrSSKl3GikN2EZKo7iR7nkHAKniBpTspddsAAAAAElFTkSu
QmCC
"
	tablelist_bicolor3_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExIRcemTPgAAAD5JREFUKM/t0jsOACAIRMHnycne
3J6IgJa6PRN+8OMzADuok0doQlp1QgNSNA5FSLudUICULZYE0s3l7NGPnffUBoaD5FpzAAAAAElF
TkSuQmCC
"
    } else {
	tablelist_bicolor3_collapsedImg put "
R0lGODlhEQAOAIABAH9/f////yH5BAEKAAEALAAAAAARAA4AAAIdjI+ZoH3AnIJRPmovznTL7jVg
5YBZ0J0opK4tqhYAOw==
"
	tablelist_bicolor3_expandedImg put "
R0lGODlhEQAOAIABAH9/f////yH5BAEKAAEALAAAAAARAA4AAAIYjI+py+1vgJx0pooXtmy/CgVc
CITmiR4FADs=
"
    }

    tablelist_bicolor3_collapsedSelImg put "
R0lGODlhEQAOAIAAAP///////yH5BAEKAAEALAAAAAARAA4AAAIdjI+ZoH3AnIJRPmovznTL7jVg
5YBZ0J0opK4tqhYAOw==
"
    tablelist_bicolor3_expandedSelImg put "
R0lGODlhEQAOAIAAAP///////yH5BAEKAAEALAAAAAARAA4AAAIYjI+py+1vgJx0pooXtmy/CgVc
CITmiR4FADs=
"
}

#------------------------------------------------------------------------------
# tablelist::bicolor4TreeImgs
#------------------------------------------------------------------------------
proc tablelist::bicolor4TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable bicolor4_${mode}Img \
		 [image create photo tablelist_bicolor4_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_bicolor4_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABcAAAASCAYAAACw50UTAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExUCuhZEJwAAAEdJREFUOMu91IsNACAIQ0HSxU03
dwf1ZIBH6IeZz7NegSIXRF4QKVGkB5EmR6YoMqaRPTiBV8GrZKkytCqKVSWqqv8VmP/zDd6/CJzv
kRcqAAAAAElFTkSuQmCC
"
	tablelist_bicolor4_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABcAAAASCAYAAACw50UTAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExY6uTmvegAAAExJREFUOMvtlNsNACAIA8/JSTd3
ApWHfmjsAD1SCvD1lBpgG3w0MqcI0GxyCgCtYiEJkCdzEgB5F0oQoEhbCAAUrSJOgE7cgv13cI86
Y04IiOwcRtoAAAAASUVORK5CYII=
"
    } else {
	tablelist_bicolor4_collapsedImg put "
R0lGODlhFwASAIABAH9/f////yH5BAEKAAEALAAAAAAXABIAAAIojI+pCusL2pshSgotznoj23kV
GIkjeWFoSK1pi5qxDJpGbZ/5/cp5AQA7
"
	tablelist_bicolor4_expandedImg put "
R0lGODlhFwASAIABAH9/f////yH5BAEKAAEALAAAAAAXABIAAAIijI+py+0Po3Sg2ovrylyzjj2g
J3YTNxlhqpJsALzyTNdKAQA7
"
    }

    tablelist_bicolor4_collapsedSelImg put "
R0lGODlhFwASAIAAAP///////yH5BAEKAAEALAAAAAAXABIAAAIojI+pCusL2pshSgotznoj23kV
GIkjeWFoSK1pi5qxDJpGbZ/5/cp5AQA7
"
    tablelist_bicolor4_expandedSelImg put "
R0lGODlhFwASAIAAAP///////yH5BAEKAAEALAAAAAAXABIAAAIijI+py+0Po3Sg2ovrylyzjj2g
J3YTNxlhqpJsALzyTNdKAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::classic1TreeImgs
#------------------------------------------------------------------------------
proc tablelist::classic1TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable classic1_${mode}Img \
		 [image create photo tablelist_classic1_${mode}Img]
    }

    tablelist_classic1_collapsedImg put "
R0lGODlhDAAKAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAMAAoAAAIgnI8Xy4EhohTOwAhk
HVfkuEHAOFKK9JkWqp0T+DQLUgAAOw==
"
    tablelist_classic1_expandedImg put "
R0lGODlhDAAKAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAMAAoAAAIcnI8Xy4EhohTOwBnr
uFhDAIKUgmVk6ZWj0ixIAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::classic2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::classic2TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable classic2_${mode}Img \
		 [image create photo tablelist_classic2_${mode}Img]
    }

    tablelist_classic2_collapsedImg put "
R0lGODlhDgAMAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAOAAwAAAInnI8Zy4whopThQAlm
NTdmak1ftA0QgKZZ2QmjwIpaiM3chJdm0yAFADs=
"
    tablelist_classic2_expandedImg put "
R0lGODlhDgAMAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAOAAwAAAIinI8Zy4whopThwDmr
uTjqwXUfBJQmIIwdZa1e66rx0zRIAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::classic3TreeImgs
#------------------------------------------------------------------------------
proc tablelist::classic3TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable classic3_${mode}Img \
		 [image create photo tablelist_classic3_${mode}Img]
    }

    tablelist_classic3_collapsedImg put "
R0lGODlhEQAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAARAA4AAAIwnI95we2Rgpi0Cris
xkZWYHGDR4GVSE4mharAC0/tFyKpsMq2lV+7dvoBdbbHI1EAADs=
"
    tablelist_classic3_expandedImg put "
R0lGODlhEQAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAARAA4AAAIrnI95we2Rgpi0Cris
xkbqyg3eN4UjaU7AygIlcn4p+Wb0Bd+4TYfi80gUAAA7
"
}

#------------------------------------------------------------------------------
# tablelist::classic4TreeImgs
#------------------------------------------------------------------------------
proc tablelist::classic4TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable classic4_${mode}Img \
		 [image create photo tablelist_classic4_${mode}Img]
    }

    tablelist_classic4_collapsedImg put "
R0lGODlhFwASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAXABIAAAJGXI6pMe0hopxUMGeq
lvdpAGhdA1WgiGVmWI0qdbZpCbOUW4L6rkd4xAuyfisUhjaJ3WYf24RYM3qKsuNmA70+U4aF98At
AAA7
"
    tablelist_classic4_expandedImg put "
R0lGODlhFwASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAXABIAAAI9XI6pMe0hopxUMGeq
lvft3TXQV4UZSZkjymEnG6kRQNc2HbvjzQM5toLJYD8P0aI7IoHKIdEpdBkW1IO0AAA7
"
}

#------------------------------------------------------------------------------
# tablelist::dustTreeImgs
#------------------------------------------------------------------------------
proc tablelist::dustTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable dust_${mode}Img \
		 [image create photo tablelist_dust_${mode}Img]
    }

    tablelist_dust_collapsedImg put "
R0lGODlhEgAQAKU0AAAAADIyMrConLGpncC6scC7ssG8s8K8tMK9tdDMxtDMx9LOyNrVztvVz9vW
ztvWz9vX0NzW0N3Y0d/a0uDd1uHe1+Lf2OPg2uTh2+Xj3efk3+jl4Ojm4enm4unn4+nn5Orn5evo
5Ovo5evq5ezp5e3q5u3q5+7s6O/t6e7t6vDu6/Hv7PHv7fLw7PLw7vT08vf39fj39fn49vn49///
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAakwJ9w
SCwSCQOBcrkcEIiGxQsWk82ushjspTgMB6zSCaVatVYq1GnkGgwFrE6IVDLZS6RQhyV4pzAZGhsc
ARwbGhkYKX1CAiYUFRYXFwGTFhUUJow/AiISnxITAROgEiKbAh0MEQGtrgEPDx2oHbEPDg8BDbay
qB68ucAevsCwvMNvIRHLzM0RIZsDHhDOzRAebkIHCiAi3t/fHwkIR0lMTAMFREEAOw==
"
    tablelist_dust_expandedImg put "
R0lGODlhEgAQAKU0AAAAADIyMrConLGpncS+tcS/tsbBuMfBucfCucfCutfTzdjUztnUz9vWztvW
z9vX0NzW0N3Y0d/a0t/a0+Dd1uHe1+Lf2OPg2uTh2+Xj3efk3+jl4Ojm4enm4unn4+vo5Ovo5evp
5uvq5ezp5e3q5u3q5+7s6O/t6e7t6vDu6/Hv7PLv7fLw7PHw7fLx7vX08vf39fj39fn49vn49///
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAagwJ9w
SCwSCQOBcrkcEIiGxQsWk82ushjspUAMBy2S6ZRSsVSpk0nkGgwFq85nRCrZSaNPZyV4ozAZGhsc
hBsaGRgofUICJRQVFhcXGJIWFRQliz8CIBGeERITEp8RIJoCHQsQAaytAQ4OHacdsA4NsAy1sace
ur6wHry/vsFvHxDIycoQH5oDHw/Lyg8fbkIHDCEg29zdCwlHSUxMAwVEQQA7
"
}

#------------------------------------------------------------------------------
# tablelist::dustSandTreeImgs
#------------------------------------------------------------------------------
proc tablelist::dustSandTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable dustSand_${mode}Img \
		 [image create photo tablelist_dustSand_${mode}Img]
    }

    tablelist_dustSand_collapsedImg put "
R0lGODlhEgAQAKU1AAAAADIyMpuWjJyXjrSxqbWxqre0rbi1rrm2r8K+tsO+t8TAuMXBusbCu8nF
vcnGvsrHv8vHwMnGwcrIwczIwMzIwc3Jw87LxMzKxc/MxdDMxdDMx9HOx9HOyNLPydPPytPQydPQ
y9TRy9TRzNXTzNXSzdfTztbUzNbUzdfVz9nV0NjW0NnW0drY097c2eDe2eXi3uXj3+jm4+nn5Oro
5f///////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAajwJ9w
SCwSCQOBcrkcEIiGCUwmm81oVmpMchgOXqWSSbVirVSm0ug1GApcm85HNKqLPp2NS+BuVSwXGRoB
GhkXFhUtfEICKQ4PEBEUARQREA8OKYs/AiEMnwwNAQ2gDCGbAhwJCgGtrgEKChyoHLGxCQGrtrNu
tbasv7KoHcGwvx2oHgvLzM0LHpsDJc7UJG1CBxgoINzd3ScYCEQFSUxMAwVEQQA7
"
    tablelist_dustSand_expandedImg put "
R0lGODlhEgAQAKU3AAAAADIyMpuWjJyXjrSxqbWxqre0rbi1rrm2r8K+tsO+t8TAuMXBusbCu8bC
vMnFvcnGvsrHv8vHwMnGwcrIwczIwMzIwc3Jw87LxMzKxc/Mxc/MxtDMxdDMx9HOx9HOyNLPydPP
ytPQydPQy9TRy9TRzNXTzNXSzdfTztbUzNbUzdfVz9nV0NjW0NnW0drY097c2eDe2eXi3uXj3+jm
4+nn5Oro5f///////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAagwJ9w
SCwSCQOBcrkcEIgGioxGq9VsVupschgOYqcTitVytVioUyk2GApgnU+IVKqTQp8OTOB+WS4YGhwb
HBoYFxYvfEICKw8QERIVFhUSERAPK4s/AiMMnwwNDg2gDCObAh4JCgGtrgEKCh6oHrGxCbi2srS6
vbGzbh++vR+oIAvIycoLIJsDJ8vRJm1CBxkqItna2ikZCEQFSUxMAwVEQQA7
"
}

#------------------------------------------------------------------------------
# tablelist::gtkTreeImgs
#------------------------------------------------------------------------------
proc tablelist::gtkTreeImgs {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable gtk_${mode}Img \
		 [image create photo tablelist_gtk_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_gtk_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAUUlEQVQoz8XTwQ2AQAhE0T17+jVQ
h/XRGIV9L5p4FsxSwAuZgbV+nHNEARzBACOijwFWVR8DVPvYA7WxN6Samd4FHHs3GslorLWxO5p6
k0/IBbP6VlQP0oOsAAAAAElFTkSuQmCC
"
	tablelist_gtk_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAW0lEQVQoz+3SwQmAQAxE0fHqKTVM
HWt7aWwsKB3Ek4IQYXVBEPzXkJdLgL/XmgA0M1PvQkQsANareSOZkrJKUpJMAK3nWIndRUrsKXLC
3H0IOTAzG0b25m8/5Aai703YBhwgYAAAAABJRU5ErkJggg==
"
	tablelist_gtk_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAa0lEQVQoz7XSMQqAMAyF4d9OAZeM
OYyeXg/TMZN0qwdQKyltxjz4CI/AxNmGKKpah2CqWs0sjKW3ZSkFMzsiWPoKolhqhRFs+Sj7Me6+
AlfXRQAigrvvLeQXEhFyzjtwdncUQYb+0bzP7kVuCWMmCi7K2XoAAAAASUVORK5CYII=
"
	tablelist_gtk_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAXUlEQVQoz2NgGAV0A4wMDAyZAgIC
04jV8OHDhywGBobp6OLMDAwMZ378+PGKg4PDm1xDYAYxEGMYPkOwgUwBAYH/6JiBgSGTnHCDG6ak
pES2ISiGUWoIDIgM7QQJACRKJBMon0pJAAAAAElFTkSuQmCC
"
    } else {
	tablelist_gtk_collapsedImg put "
R0lGODlhEgAOAMIFAAAAABAQECIiIoaGhsPDw////////////yH5BAEKAAcALAAAAAASAA4AAAMi
eLrc/pCFCIOgLpCLVyhbp3wgh5HFMJ1FKX7hG7/mK95MAgA7
"
	tablelist_gtk_expandedImg put "
R0lGODlhEgAOAMIFAAAAABAQECIiIoaGhsPDw////////////yH5BAEKAAcALAAAAAASAA4AAAMg
eLrc/jDKSWu4OAcoSPkfIUgdKFLlWQnDWCnbK8+0kgAAOw==
"
	tablelist_gtk_collapsedActImg put "
R0lGODlhEgAOAKEDAAAAABAQEBgYGP///yH5BAEKAAMALAAAAAASAA4AAAIdnI+pyxjNgoAqSOrs
xMNq7nlYuFFeaV5ch47raxQAOw==
"
	tablelist_gtk_expandedActImg put "
R0lGODlhEgAOAKEDAAAAABAQECIiIv///yH5BAEKAAMALAAAAAASAA4AAAIYnI+py+0PY5i0Bmar
y/fZOEwCaHTkiZIFADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::klearlooksTreeImgs
#------------------------------------------------------------------------------
proc tablelist::klearlooksTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable klearlooks_${mode}Img \
		 [image create photo tablelist_klearlooks_${mode}Img]
    }

    tablelist_klearlooks_collapsedImg put "
R0lGODlhEAAOAIABAAAAAP///yH5BAEKAAEALAAAAAAQAA4AAAIVjI+py+1vAIBR0iAnzZA//2nX
SD4FADs=
"
    tablelist_klearlooks_expandedImg put "
R0lGODlhEAAOAIABAAAAAP///yH5BAEKAAEALAAAAAAQAA4AAAIVjI+py+0PEwBntkmxw/bpSEXi
SIoFADs=
"
}

#------------------------------------------------------------------------------
# tablelist::mateTreeImgs
#------------------------------------------------------------------------------
proc tablelist::mateTreeImgs {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable mate_${mode}Img \
		 [image create photo tablelist_mate_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_mate_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsIAAA7CARUoSoAAAAAHdElNRQfgBQkTFQk/cTJBAAAAGnRFWHRTb2Z0
d2FyZQBQYWludC5ORVQgdjMuNS4xMDD0cqEAAABvSURBVChTY/j//z/JGKsgIYxVkBBGMBgYJJAl
8GEEg4FhCxCnIEviwggGA8N+IF4MxKuBWB9ZETpGMCCaKoF4AhBvBuIOIMbqZAQDoakBiFuBeAcQ
rwRiDI3YNJFsE8l+Iiv0SI8nUjBWQfz4PwMAdOLOFUtMsZ8AAAAASUVORK5CYII=
"
	tablelist_mate_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwQAADsEBuJFr7QAAAAd0SU1FB+AFCRMYGg5hDdIAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAIVJREFUKFOV0DESQDAQBdB/AD2ncCKNS2h0ZjROoUFHoXO5+EuYkB07
ipdN/u42gXPuNzW0qKFFDS3nAaS00KaQPI2W/GJBPVUBeZfhwjF7X4CMRuqo9nWiJFw4Zh8PIKeZ
Gl/zsH/PRQHQ0ir13bvEwfkpg9R376KHHwtCDS1qaFHDbw47S7vHxT1vFYcAAAAASUVORK5CYII=
"
	tablelist_mate_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwQAADsEBuJFr7QAAAAd0SU1FB+AFCRMaDb+E6pcAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAG9JREFUKFNj+P//P8kYqyAhjFWQEEYwGBgkkCXwYQSDgeEIEE9GlsSF
EQwGhv1AvAeI9wJxMLIidIxgQDQtBeLNQAyydQMQ6yArhquFMxCaVgLxOigfZCuGX7FpItkmkv1E
VuiRHk+kYKyC+PF/BgB1jdECrfqPqwAAAABJRU5ErkJggg==
"
	tablelist_mate_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwQAADsEBuJFr7QAAAAd0SU1FB+AFCRMbDj+WimwAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAHZJREFUKFOVkNsJwCAMRe8WbtOF3KrQAUpf4HKp1ihRg6Efx5CTe38E
Ef1GlRaqtFClRX4AFwkT3FDi4sqBXZD2TRa+bLPk0BM5eAZ5r7lmAXwKRk6eXt5rbhDAxYW7vxVG
ASxcWvpbQZfdb/Wo0kKVFqqcQ3gBKsLRaJdxo5AAAAAASUVORK5CYII=
"
    } else {
	tablelist_mate_collapsedImg put "
R0lGODlhDQAOAOMOAAAAAEBAQEdHR0tLS0xMTFRUVFZWVlxcXG9vb3d3d3p6en9/f4aGhpubm///
/////yH5BAEKAA8ALAAAAAANAA4AAAQf8MlJq70459H0C0ehBQxCJBi5KIJxkSb6hhrn3fgdAQA7
"
	tablelist_mate_expandedImg put "
R0lGODlhDQAOAIQQAAAAAEVFRUxMTFBQUFFRUVhYWFlZWVpaWl9fX3V1dXp6en19fYSEhImJiZ6e
nqOjo////////////////////////////////////////////////////////////////yH5BAEK
AAAALAAAAAANAA4AAAUlICCOZGmeaJoOQdsO5oM0NOKcRsIkRUosBJVCoFABDsakcpkKAQA7
"
	tablelist_mate_collapsedActImg put "
R0lGODlhDQAOAOMLAAAAADs7O0BAQEJCQkNDQ0xMTE9PT1FRUVZWVlpaWmxsbP//////////////
/////yH5BAEKAA8ALAAAAAANAA4AAAQf8MlJq70456D0E8SgCUkRGBiJHIJokSZ6gS7GeXiORwA7
"
	tablelist_mate_expandedActImg put "
R0lGODlhDQAOAOMKAAAAAEVFRUhISElJSUpKSktLS0xMTE5OTlpaWl1dXf//////////////////
/////yH5BAEKAA8ALAAAAAANAA4AAAQg8MlJq70458B7sElwjAFyBYIhfFhQsBgRDNoD13iuWxEA
Ow==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::mintTreeImgs
#------------------------------------------------------------------------------
proc tablelist::mintTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable mint_${mode}Img \
		 [image create photo tablelist_mint_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_mint_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA6/AAAOvwE4BVMkAAAAB3RJTUUH4AgVETkWapOs4gAAAFRJREFUKM/F0csJgDAQBcAht7Qj
NmERVpajRdiEWIJt5GoFWYxEfMdlB/bDnylv0IUtakiN+hTBFsoRTMEUGTP2HtS9E1QcWJ6iihPr
sJMPe+43uQEqOwsax3OY5AAAAABJRU5ErkJggg==
"
	tablelist_mint_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA6/AAAOvwE4BVMkAAAAB3RJTUUH4AgVEgAUiF/+LQAAAFlJREFUKM/t0bEJgDAQRuFPdAIH
Su0YFg7mLFnAzjLgFpY2EVIEiaXgg+O443/XHD+gyz1gbcjPiH0eDmyYMFTCJxbE2qWAHamoPe8f
KcUmoRTTG+Fm/OhzL/U/D1OvbHP6AAAAAElFTkSuQmCC
"
	tablelist_mint_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA6+AAAOvgHqQrHAAAAAB3RJTUUH4AgVETo0lN6+xQAAAE1JREFUKM9jYBgw8P///3nkaHrx
////5fjUMOEQt8CnEZcmTnwamfC4AqZxHymaSPYTAwMDw3cGBoYTjIyMTsSG3n1CIUhykFMncmkG
AH8QL3kc9+eHAAAAAElFTkSuQmCC
"
	tablelist_mint_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI    
WXMAAA6/AAAOvwE4BVMkAAAAB3RJTUUH4AgVEgEbAfvS/QAAAFhJREFUKM/t0cEJwCAQRNE/gfRk
GZaaMuzCqx14nFwSEIPoVcjAnnYeLCz8AUAAtgNwLfSjpHQASEpABOqgXF/w2dgOtrPt0kx+Lhmn
g3PQwbIMGnhu+twbiKFCUb0So1cAAAAASUVORK5CYII=
"
    } else {
	tablelist_mint_collapsedImg put "
R0lGODlhDQAOAMIHAAAAACEhISgoKCoqKkhISFxcXGRkZP///yH5BAEKAAcALAAAAAANAA4AAAMd
eLrc/spAFspUYdgZ8n5dIBBQOJYep13VdUhufCUAOw==
"
	tablelist_mint_expandedImg put "
R0lGODlhDQAOAKEDAAAAACEhISkpKf///yH5BAEKAAMALAAAAAANAA4AAAIXnI+py+0/gpwzCRrE
ulKz6zUBRJYmUgAAOw==
"
	tablelist_mint_collapsedSelImg put "
R0lGODlhDQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAANAA4AAAIXhI+pa8EY3ANRsmoV
zhDf+oAhp03mCRQAOw==
"
	tablelist_mint_expandedSelImg put "
R0lGODlhDQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAANAA4AAAIShI+py+0Pgpwz0apu
wxv6DyIFADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::mint2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::mint2TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable mint2_${mode}Img \
		 [image create photo tablelist_mint2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_mint2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADr4AAA6+AepCscAAAAAHdElNRQfgBQkTHSnMxpiBAAAAGnRFWHRTb2Z0
d2FyZQBQYWludC5ORVQgdjMuNS4xMDD0cqEAAABRSURBVChTpZGxCQAgDAR/fkdwMitXiYqFPsRE
Y3HFPRwEhYg8o44eLEDa/QQLUDt53zRYZlS8kGVGbsiyIjNk+Yyezws9hBkMWCKfe4s62gga8dTd
YGVViS0AAAAASUVORK5CYII=
"
	tablelist_mint2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOvgAADr4B6kKxwAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAYklE
QVQoU5XLQQqAMAxE0ZzBW/T+lxDciK49S5rUGiidZrDwFh3yRVV/gyMDRwaODBwZf8Wc5klcpkTU
Sw8Pg4LbRBBREk5Bux0+YwiDdjcNb7ivAodHkQ3tHzgycGTgmFOpl2jLGnIdx90AAAAASUVORK5C
YII=
"
	tablelist_mint2_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOvAAADrwBlbxySQAAAAd0SU1FB+AFCRMdKczGmIEAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAFVJREFUKFOlkDEKwDAMA/N7736If+dZjYcOAlPF6XCEEzkIWQDGtKOC
xN33wRc6SMwMJyFJRREhQ5KKMlOGJG+kQpJf0fh5Vx+hgoLkJCjaUdGO32A9XVwfc0mdLjYAAAAA
SUVORK5CYII=
"
	tablelist_mint2_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOvQAADr0BR/uQrQAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAW0lE
QVQoU5XLwQ3AIAxDUbbPjckyRJbIOcg9VG1xsHp4SHzwqKrfaFRoVGhUaFSuY85ZZtbC+zYCPERE
ZeYN9+8AXpfnsBvAFvDR3dsB0HgaAI0KjQqNCo1nNRZ9ViCcGRAOXQAAAABJRU5ErkJggg==
"
    } else {
	tablelist_mint2_collapsedImg put "
R0lGODlhDQAOAMIFAAAAACEhIScnJ2VlZXV1df///////////yH5BAEKAAcALAAAAAANAA4AAAMc
eLrc/odAFsZUQdgZ8n6dB4XaKI4l90HS5b5HAgA7
"
	tablelist_mint2_expandedImg put "
R0lGODlhDQAOAMIHAAAAACIiIiwsLC0tLS8vLzQ0NDc3N////yH5BAEKAAcALAAAAAANAA4AAAMZ
eLrc/jDKSYK9YbSCg3ic9UHcGBlTqq5RAgA7
"
	tablelist_mint2_collapsedSelImg put "
R0lGODlhDQAOAMIFAAAAAIeHh5KSkq6urvX19f///////////yH5BAEKAAcALAAAAAANAA4AAAMd
eLrc/kdAFuQ8YVgYiJ6dtzXh93TmmZ7j017wlAAAOw==
"
	tablelist_mint2_expandedSelImg put "
R0lGODlhDQAOAMIGAAAAAIeHh46OjszMzODg4PX19f///////yH5BAEKAAcALAAAAAANAA4AAAMa
eLrc/jDKKYK9QTRBiieawxVgJAyhOa1sGyUAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::newWaveTreeImgs
#------------------------------------------------------------------------------
proc tablelist::newWaveTreeImgs {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable newWave_${mode}Img \
		 [image create photo tablelist_newWave_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_newWave_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAAHdElNRQfgBQkTJAyJRsF8AAAAGnRFWHRTb2Z0
d2FyZQBQYWludC5ORVQgdjMuNS4xMDD0cqEAAADQSURBVDhPY6A7+P//P5SFBfj4+PAB8QxfX19R
qBBWQMgQAQ8Pjw/u7u73gexCIGaFSqEAgoY4OzvfYmNjyzczM9vk7e19ESjmBZWGA4KGuLi4XAUy
I0BYVFQ0y9HR8RBQfCsQa4AVAQFBQ9zc3C4CmW7IWENDIx/oxctA+X6QGoKGABWfATJNkLGOjk4K
MKxAXiPOEE9PzxNAphIIq6qqWgNdthkoTpp3vLy8DsvKykoCNXcA+eeAmPSABeLHQAxyOtlRTHli
IxZQxRDsgIEBAK1PZ2HAQtNpAAAAAElFTkSuQmCC
"
	tablelist_newWave_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAAHdElNRQfgBQkTJh3RwIMMAAAAGnRFWHRTb2Z0
d2FyZQBQYWludC5ORVQgdjMuNS4xMDD0cqEAAACySURBVDhPYxiGwMfHhw+IBQhgPqhy7ACoYIaH
h8cHJyenu9gwSA6kBqocO/D19RUFKrzHxsaWD+RmIWOQGEgOpAbIxw+ANhVaWFisBjIjkDFIDCQH
ZBMGQIWs3t7eFyQkJKKBXDcQBrFBYiA5sCJiAFCxl4uLyw4g0xSEQWyQGFiSFADUtNXExCQMhEFs
qDBpAKhRA+iFUyAMYkOFSQdAzf0gDOWSB4AGgBMYlEsPwMAAAFjwRMOCm1MPAAAAAElFTkSuQmCC
"
	tablelist_newWave_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAAHdElNRQfgBQkTJzSKaSohAAAAGnRFWHRTb2Z0
d2FyZQBQYWludC5ORVQgdjMuNS4xMDD0cqEAAADeSURBVDhPY6A7+P//P5SFBZiYmPAZGxvPAGJR
qBBWQMgQATtT4z/2psZvgAYVAvmsUCkUQNAQHwvjH7M8DJ+k2xl9tDAxvg40zAsqDQeEDbE0/r7I
1+gBCE/xMnocbmP8BWjQNiDWgCojbIivlfG3pYHGd5Fxp5fxEw9L489Ag/qBWICwIdbGX1eEmtxE
xl0+Jo+Ahnwi2hA/a5OvayLNroHwnBDTW5H2Jh+BGknzjp+NyZdVMeaXc9xMX1iYGl8DaiY9YO3N
jX85Wpi8AmomO4opT2zEAqoYgh0wMAAArYN9OA1qURYAAAAASUVORK5CYII=
"
	tablelist_newWave_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAACxIAAAsSAdLdfvwAAAAHdElNRQfgBQkTKQLbUJI2AAAAGnRFWHRTb2Z0
d2FyZQBQYWludC5ORVQgdjMuNS4xMDD0cqEAAAC6SURBVDhPYxiGwMTEhA+IBQhgPqhy7MDY2HiG
ranxH29zo5/YMEgOpAaqHDsAKhC1NzV+M8PV4NkcN1QMEgPJgdRAleMGQEWF6fZGHxb6GD1ExiAx
kBxUGX4A9DOrhYnxtem+xg+WBhrfBWEQGyQGkoMqIwyANnpF2Jl8XBVuegOEQWyQGFSaeADUtK0v
0PQuCJsA2VBh0gDQEA1Pa5MPIAxiQ4VJB0DN/SAM5ZIHgAYIgDCUSw/AwAAAH1NYxpYmHp0AAAAA
SUVORK5CYII=
"
    } else {
	tablelist_newWave_collapsedImg put "
R0lGODlhEQAOAIQdAAAAAFJSUl5eXl9fX2JiYmZmZmdnZ2lpaWtra2xsbG5ubnBwcHJycnR0dH19
fX9/f5KSkpSUlJqampycnJ2dnaGhoaenp6ysrLm5ucvLy8zMzN3d3ejo6P///////////yH5BAEK
AB8ALAAAAAARAA4AAAU44CeOZGmeaISigbCaAsQg70hYFqU8tYH9mEpBskJkjpnLgYhabDYaB+/V
4EwUNdEgkR2puuBwKQQAOw==
"
	tablelist_newWave_expandedImg put "
R0lGODlhEQAOAIQSAAAAAFJSUltbW19fX2xsbHBwcHh4eHl5eX9/f5KSkpSUlJWVlZqamqenp6ys
rLm5ubq6usrKyv///////////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAARAA4AAAU04CeOZGmeaKquoxIIcBwo6JAs+JIM6tH8jcOK4Hg8HASWIRIxsD4ICATx
/BQK1Q+Dke0+QwA7
"
	tablelist_newWave_collapsedActImg put "
R0lGODlhEQAOAKUgAAAAAEA3NUI6N1A9OFE/OVNAOlNCO1BCPFFDPVRCO1VEPF5EO2JJP29IPU1E
QlBIRFdTU1dVU3lWR21tbZVdSJ9dSJdgS6RbRq1iSqpsUrFoTrRuUrlzVrh4WYWFhYyMjP//////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAAAALAAAAAARAA4AAAY8QIBw
SCwaj0gPEhlwLI2DSwPyHBIwmMpiUi1ovhrK4bM0bM4bC4KMTHA4GQb3qehIIlWh4JEfKvuAgUVB
ADs=
"
	tablelist_newWave_expandedActImg put "
R0lGODlhEQAOAIQSAAAAAD83NU87NlNGP2FIP29KPk1EQldUU21tbZ1oT6JXRKVYRKNiS6xhSrFo
TrdwU4WFhYyMjP///////////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAARAA4AAAU04CeOZGmeaKquIxQIcBxAqKEs+KIYatH8jcLqwHA4GAcW4fEgsD6IRALx
/AwG1U8kku0+QwA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::oxygen1TreeImgs
#------------------------------------------------------------------------------
proc tablelist::oxygen1TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable oxygen1_${mode}Img \
		 [image create photo tablelist_oxygen1_${mode}Img]
    }

    tablelist_oxygen1_collapsedImg put "
R0lGODlhEAAOAKECAAAAABQTEv///////yH5BAEKAAAALAAAAAAQAA4AAAIShI+py+0PVYhmwoBx
tJv6D0YFADs=
"
    tablelist_oxygen1_expandedImg put "
R0lGODlhEAAOAKECAAAAABQTEv///////yH5BAEKAAAALAAAAAAQAA4AAAIPhI+py+0Po2yh1omz
3rwAADs=
"
}

#------------------------------------------------------------------------------
# tablelist::oxygen2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::oxygen2TreeImgs {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable oxygen2_${mode}Img \
		 [image create photo tablelist_oxygen2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_oxygen2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AgXFB4trZ/9wwAAAFpJREFUKM/t0rENQGAUReEv0UgM
YgEVlUQjEttYRaGyixXEABpraBR/67Wc6jbn3lc8flI6jG+lLMklZhTYoldU2LE+RSEaXJgico0D
C/K38oAzugwt+g9+3w3IEAlJihLp4AAAAABJRU5ErkJggg==
"
	tablelist_oxygen2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AgXFCEWREo+2wAAAFdJREFUKM/t0iEKgEAQheEvCl7H
pEmwLIK3MXkTk4cSuxavYdlkWhfj/m1eGP4ZHoXf6DG+soAhdUHAhTbODU5MXyxmHOiwY8k5ZcWN
LfcXVTSpSy3SeQBkeAlg0OObegAAAABJRU5ErkJggg==
"
	tablelist_oxygen2_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AgXFB85rl4Y/wAAAHtJREFUKM/tkiEOwkAURN9v6H1W
VFWTIJpwhu82AY3qMVZi9g4ILrHin4E7gP04ssF93Y4aM5OZycCOH9T8qObnqG7o+AgUNV8jBvKX
YgIq0IBrTfKOJKAmaUAGTsAlWgE1n4E78ABKdMRFzV9qfovoDh3/ALkmeW7sgF/KlyBRWhng6wAA
AABJRU5ErkJggg==
"
	tablelist_oxygen2_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AgXFCIMkgWUYgAAAHdJREFUKM9jYBgF1AEJF/47Jlz4
740m5plw4b8LIb1MUJqDgYFhesKF/1ZQzSYMDAwzGBgYuAgZwIhkYykDA0MiAwNDKgMDw0wGBobl
CwwYW4k2AGrILAYGBl8GBoadCwwYE4jxPgsaP4+BgeE2AwPDtNGUQTwAAF28HMqTOZpSAAAAAElF
TkSuQmCC
"
    } else {
	tablelist_oxygen2_collapsedImg put "
R0lGODlhEAAOAIABAAAAAP///yH5BAEKAAEALAAAAAAQAA4AAAIVjI+py+0PwDtRzlAvjjND3lna
SF4FADs=
"
	tablelist_oxygen2_expandedImg put "
R0lGODlhEAAOAIABAAAAAP///yH5BAEKAAEALAAAAAAQAA4AAAIVjI+py+0PDwCSskmxwxPqaEXi
SI4FADs=
"
	tablelist_oxygen2_collapsedActImg put "
R0lGODlhEAAOAKECAAAAAGDQ/////////yH5BAEKAAAALAAAAAAQAA4AAAIVhI+py+0fwjtRTlAv
jjND3lnaSF4FADs=
"
	tablelist_oxygen2_expandedActImg put "
R0lGODlhEAAOAKECAAAAAGDQ/////////yH5BAEKAAAALAAAAAAQAA4AAAIVhI+py+0PTwiSskmx
wxPqaEXiSI4FADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::phaseTreeImgs
#------------------------------------------------------------------------------
proc tablelist::phaseTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable phase_${mode}Img \
		 [image create photo tablelist_phase_${mode}Img]
    }

    tablelist_phase_collapsedImg put "
R0lGODlhEAAOAKECAAAAAMfHx////////yH5BAEKAAAALAAAAAAQAA4AAAIYhI+py63hUoDRTBov
bnovXV0VMI2kiaIFADs=
"
    tablelist_phase_expandedImg put "
R0lGODlhEAAOAKECAAAAAMfHx////////yH5BAEKAAAALAAAAAAQAA4AAAIThI+py+0PT5iUsmob
hpnHD4ZhAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::plain1TreeImgs
#------------------------------------------------------------------------------
proc tablelist::plain1TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plain1_${mode}Img \
		 [image create photo tablelist_plain1_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_plain1_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAYAAACALL/6AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwYtcCg47AAAACpJREFUGNNjYKAA1BOjiIlUTUyk
2sREqvOYSPUTPg2NpGhoJMVJjVSNBwD8+gSMwdvvHwAAAABJRU5ErkJggg==
"
	tablelist_plain1_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAYAAACALL/6AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwkTNtE5iAAAAC9JREFUGNNjYBh0gJGBgaGeCHWN
yBoYCGhqRLeBAY+mRmxOYsChqZFYf9UPbLACACL9BIS+a6kZAAAAAElFTkSuQmCC
"
    } else {
	tablelist_plain1_collapsedImg put "
R0lGODlhDAAKAIABAH9/f////yH5BAEKAAEALAAAAAAMAAoAAAIUjI8IybB83INypmqjhGFzxxkZ
UgAAOw==
"
	tablelist_plain1_expandedImg put "
R0lGODlhDAAKAIABAH9/f////yH5BAEKAAEALAAAAAAMAAoAAAIQjI+py+D/EIxpNscMyLyHAgA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::plain2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::plain2TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plain2_${mode}Img \
		 [image create photo tablelist_plain2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_plain2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAMCAYAAABSgIzaAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwwFv3J4nAAAADJJREFUKM9jYKASaCJWIRO5mpnI
tZmJXGczketnJnIDjBiNdeRorCPHqXXkBE4dzVIOAPKWBZkKDbb3AAAAAElFTkSuQmCC
"
	tablelist_plain2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAMCAYAAABSgIzaAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEw4I8/VmowAAADZJREFUKM9jYBgygJGBgaGeBPWN
yBoZiNTciG4jAxGaG7E5lYGA5kZcfmTAo7mR1ECrZxg+AAC4iAWFJSdDXQAAAABJRU5ErkJggg==
"
    } else {
	tablelist_plain2_collapsedImg put "
R0lGODlhDgAMAIABAH9/f////yH5BAEKAAEALAAAAAAOAAwAAAIXjI9poA3c0IMxTOpuvS/yPVVW
J5KlWAAAOw==
"
	tablelist_plain2_expandedImg put "
R0lGODlhDgAMAIABAH9/f////yH5BAEKAAEALAAAAAAOAAwAAAIUjI+pywoPI0AyuspkC3Cb6YWi
WAAAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::plain3TreeImgs
#------------------------------------------------------------------------------
proc tablelist::plain3TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plain3_${mode}Img \
		 [image create photo tablelist_plain3_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_plain3_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExAQNNjBKgAAADtJREFUKM9jYKABqCdHExM1DGKi
houYqOE1JmqEERM1ApuJGrFGrCGNlBrSSKl3GikN2EZKo7iR7nkHAKniBpTspddsAAAAAElFTkSu
QmCC
"
	tablelist_plain3_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExIRcemTPgAAAD5JREFUKM/t0jsOACAIRMHnycne
3J6IgJa6PRN+8OMzADuok0doQlp1QgNSNA5FSLudUICULZYE0s3l7NGPnffUBoaD5FpzAAAAAElF
TkSuQmCC
"
    } else {
	tablelist_plain3_collapsedImg put "
R0lGODlhEQAOAIABAH9/f////yH5BAEKAAEALAAAAAARAA4AAAIdjI+ZoH3AnIJRPmovznTL7jVg
5YBZ0J0opK4tqhYAOw==
"
	tablelist_plain3_expandedImg put "
R0lGODlhEQAOAIABAH9/f////yH5BAEKAAEALAAAAAARAA4AAAIYjI+py+1vgJx0pooXtmy/CgVc
CITmiR4FADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::plain4TreeImgs
#------------------------------------------------------------------------------
proc tablelist::plain4TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plain4_${mode}Img \
		 [image create photo tablelist_plain4_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_plain4_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABcAAAASCAYAAACw50UTAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExUCuhZEJwAAAEdJREFUOMu91IsNACAIQ0HSxU03
dwf1ZIBH6IeZz7NegSIXRF4QKVGkB5EmR6YoMqaRPTiBV8GrZKkytCqKVSWqqv8VmP/zDd6/CJzv
kRcqAAAAAElFTkSuQmCC
"
	tablelist_plain4_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABcAAAASCAYAAACw50UTAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExY6uTmvegAAAExJREFUOMvtlNsNACAIA8/JSTd3
ApWHfmjsAD1SCvD1lBpgG3w0MqcI0GxyCgCtYiEJkCdzEgB5F0oQoEhbCAAUrSJOgE7cgv13cI86
Y04IiOwcRtoAAAAASUVORK5CYII=
"
    } else {
	tablelist_plain4_collapsedImg put "
R0lGODlhFwASAIABAH9/f////yH5BAEKAAEALAAAAAAXABIAAAIojI+pCusL2pshSgotznoj23kV
GIkjeWFoSK1pi5qxDJpGbZ/5/cp5AQA7
"
	tablelist_plain4_expandedImg put "
R0lGODlhFwASAIABAH9/f////yH5BAEKAAEALAAAAAAXABIAAAIijI+py+0Po3Sg2ovrylyzjj2g
J3YTNxlhqpJsALzyTNdKAQA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::plastikTreeImgs
#------------------------------------------------------------------------------
proc tablelist::plastikTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plastik_${mode}Img \
		 [image create photo tablelist_plastik_${mode}Img]
    }

    tablelist_plastik_collapsedImg put "
R0lGODlhDwAOAMIDAAAAAHZ2drW1tf///////////////////yH5BAEKAAQALAAAAAAPAA4AAAMq
SLrc/jAqEWoVj469A24BB3CBE25jZw5A2w4lKJIrSjcaB3+4dUnA4CIBADs=
"
    tablelist_plastik_expandedImg put "
R0lGODlhDwAOAMIDAAAAAHZ2drW1tf///////////////////yH5BAEKAAQALAAAAAAPAA4AAAMo
SLrc/jAqEWoVj469A24BJwZOKHblAKzrQIInCscvo41fQ1me5P+LBAA7
"
}

#------------------------------------------------------------------------------
# tablelist::plastiqueTreeImgs
#------------------------------------------------------------------------------
proc tablelist::plastiqueTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plastique_${mode}Img \
		 [image create photo tablelist_plastique_${mode}Img]
    }

    tablelist_plastique_collapsedImg put "
R0lGODlhEQAOAOMLAAAAAHp4eH59fa+trfHx8fPz8/X19ff39/n5+fv7+/39/f//////////////
/////yH5BAEKAA8ALAAAAAARAA4AAAQ+8MlJq7042yG6FwMmKGSpCGKiBmqCXgIiBzLyWsIR7Ptx
VwKDMCA0/CiCgjKgLBwnAoJ0SnhKOJ9OSMPtYiIAOw==
"
    tablelist_plastique_expandedImg put "
R0lGODlhEQAOAOMLAAAAAHp4eH59fa+trfHx8fPz8/X19ff39/n5+fv7+/39/f//////////////
/////yH5BAEKAA8ALAAAAAARAA4AAAQ78MlJq7042yG6FwMmKGSpCGKirgl6CUgsI64lHEGeH3Ul
GMCgoUcRFI7IAnEiIDifhKWE8+mENNgsJgIAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::radianceTreeImgs
#------------------------------------------------------------------------------
proc tablelist::radianceTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable radiance_${mode}Img \
		 [image create photo tablelist_radiance_${mode}Img]
    }

    tablelist_radiance_collapsedImg put "
R0lGODlhEgAQAKUoAAAAAEBAQOTe1eTe1uTf1+bh2ejj2ujk3erl3uvn4Ozo4u3p4+7q5O/r5u/s
5+/t6PDt6PPw7PLw7fXz8Pb08ff18vb18/f28vj28fj28vj28/j39Pj39fj49fn49/n5+Pr6+Pv7
+fz8+fz8+vz8+/39/P39/f7+/f//////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAaZwJ9w
SCwWD4KkUnkwFjAj02k6NY0oBeLBQiKVvuBS19IUCkCgkGjEZotCaMFQ4Kl/7oH7p+6RmzkcGxsc
HQEdgYAcfj8CGhoZGhQVARUVF44aiwIUFBMBn6ABnBSaEhESqBIBqamaEA+wsAGxsBCaC7i5Abm4
DJoJCMHCwwgKiwcNBsrLzAYOZUIFCgQD1dYDBApZR0vd0EJBADs=
"
    tablelist_radiance_expandedImg put "
R0lGODlhEgAQAKUoAAAAAEBAQOTe1eTe1uTf1+bh2ejj2ujk3erl3uvn4Ozo4u3p4+7q5O/r5u/s
5+/t6PDt6PPw7PLw7fXz8Pb08ff18vb18/f28vj28fj28vj28/j39Pj39fj49fn49/n5+Pr6+Pv7
+fz8+fz8+vz8+/39/P39/f7+/f//////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAaTwJ9w
SCwWD4KkUnkwFjAj02k6NY0oBeLBQiKVvuBS19IUCkCgkGjEZotCaMFQ4Kl/7vhP3SM3czgbGxwd
hIB/HH0/AhoaGRoUFRcVkYwaiQIUFBMBnJ0BmRSXEhESpaanEpcQD6ytrg8QlwuztLWzDJcJCLu8
vQgKiQcNBsTFxgYOZUIFCgQDz9ADBApZR0vXykJBADs=
"
}

#------------------------------------------------------------------------------
# tablelist::ubuntuTreeImgs
#------------------------------------------------------------------------------
proc tablelist::ubuntuTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable ubuntu_${mode}Img \
		 [image create photo tablelist_ubuntu_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_ubuntu_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAsAAAAOCAYAAAD5YeaVAAAAgElEQVQoz73ROwrCUBSE4Q8jATtR
AkoWpZCVuA8xO0gr2LgdF+Cj0CJ1bGyuTUhuECTTzTn/FMMwllaxZ9LyFd64dMGTlk9RoEQ+BMMN
sxAohmCoccUmhNYxGBo8QukDsmkETrHEHXs8++A5Fjji/D12wTle2IWyvTph+5cFf9IH6EoSOPaU
kccAAAAASUVORK5CYII=
"
	tablelist_ubuntu_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAsAAAAOCAYAAAD5YeaVAAAAiklEQVQoz9XRIQoCYRAF4M8VXCzC
j2lFTJ7H5C02eA+bd9BgEBeP4R3MBrVZNFn+hZ8/qEnwwYThvZl5vOH/0EGFFfpvdE8surjjgSlO
uGTVwxbHIk4ecEXINgbcsIciIZYYoIx9iVDX9Sb1nGKGOc4YYYemJYtM3NqZxPPNp4QqrDH+NtLh
bz/4Au5zF3nYGscDAAAAAElFTkSuQmCC
"
	tablelist_ubuntu_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAsAAAAOCAYAAAD5YeaVAAAAiElEQVQoz72SoQoCURREz11YweIv
uFEQo83id+wvWMT/M4nFbhCxLNjXKMixaHks6xPEaQOHO8xw4S9Sp9/AN3WTC9/Vq3roSikSXwIn
YATs05RILwO7lx0CY6AB6og498FvzYAHMC96KgyACXABFhHRdBXcqke1Vde5a1SfpmvVVe7Oy5+9
wxNzbFn4+q5BGgAAAABJRU5ErkJggg==
"
	tablelist_ubuntu_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAsAAAAOCAYAAAD5YeaVAAAAj0lEQVQoz9WRMQ4BARBF30ejICKa
jUg4z15EOMsewC00nEOhlJAoHEDUT7MrCkQl8ZufmXnF/Bn4P0WdAlug/4G7AWUnyUmtgAVwfAHO
gFWSQ5qOugF6wOUJLIBrkhKg9TSYA0OgW9ddYAQsG+ABJzkDFTAG2rVXSU5vk6hrdV+v9Vlqoe7U
yVf3VAe//eAdhJ0u3C54tZ8AAAAASUVORK5CYII=
"
    } else {
	tablelist_ubuntu_collapsedImg put "
R0lGODlhCwAOAKECAAAAAExMTP///////yH5BAEKAAAALAAAAAALAA4AAAIWhI+py8EWYotOUZou
PrrynUmL95RLAQA7
"
	tablelist_ubuntu_expandedImg put "
R0lGODlhCwAOAKECAAAAAExMTP///////yH5BAEKAAAALAAAAAALAA4AAAIThI+pyx0P4Yly0pDo
qor3BoZMAQA7
"
	tablelist_ubuntu_collapsedSelImg put "
R0lGODlhCwAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAALAA4AAAIWhI+py8EWYotOUZou
PrrynUmL95RLAQA7
"
	tablelist_ubuntu_expandedSelImg put "
R0lGODlhCwAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAALAA4AAAIThI+pyx0P4Yly0pDo
qor3BoZMAQA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::ubuntu2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::ubuntu2TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable ubuntu2_${mode}Img \
		 [image create photo tablelist_ubuntu2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_ubuntu2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAOCAYAAAD9lDaoAAAAP0lEQVQoz2NgGFBQRYyijwwMDBaE
FB1mYGDYh66QCYtCVgYGhjZkhUzkOByrddgUYShgRuNLMjAwLB/YWGAAAKvHB5tkvnheAAAAAElF
TkSuQmCC
"
	tablelist_ubuntu2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAOCAYAAAD9lDaoAAAAUElEQVQoz9XMsQmAQBSD4U+vcAJL
O5dxI7FxLGuxORzFFWxs3oEIDnBpEsKfUKma8AXTD7OlCAcG9Oiiu5GxptdixxhgixMzpM91Aa8C
VK0HIeMJSGA/nM0AAAAASUVORK5CYII=
"
	tablelist_ubuntu2_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAOCAYAAAD9lDaoAAAAQElEQVQoz2NgGFAgjk2QCY3Py8DA
wENIEcP////1sClEBir/IcAKWSETOQ5XQTcFqyJsCpjR+KwMDAzvBzYWGACK6w9f19Y/wAAAAABJ
RU5ErkJggg==
"
	tablelist_ubuntu2_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAOCAYAAAD9lDaoAAAAP0lEQVQoz2NgGKKAEUqLMDAw8OJQ
8xmZw/f//3+D/whgw8DAwI1sErJCJQYGBh5GRsbzDAwMX3E5gQ9mwpAHAI7TFKfP6kUoAAAAAElF
TkSuQmCC
"
    } else {
	tablelist_ubuntu2_collapsedImg put "
R0lGODlhCQAOAMIEAAAAAA4ODjw8PEFBQf///////////////yH5BAEKAAEALAAAAAAJAA4AAAMR
GLrc/nAJKMYT1WHbso5gGCYAOw==
"
	tablelist_ubuntu2_expandedImg put "
R0lGODlhCQAOAMIEAAAAADw8PEFBQUpKSv///////////////yH5BAEKAAAALAAAAAAJAA4AAAMR
CLrc/jCqQCsbVLihpf+glAAAOw==
"
	tablelist_ubuntu2_collapsedSelImg put "
R0lGODlhCQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAJAA4AAAIOhI+py43BAlRyTYez
BgUAOw==
"
	tablelist_ubuntu2_expandedSelImg put "
R0lGODlhCQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAJAA4AAAINhI+py+0WYlDx2YtX
AQA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs {{treeStyle "vistaAero"}} {
    variable scalingpct
    vistaAeroTreeImgs_$scalingpct $treeStyle
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs_100
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs_100 {{treeStyle "vistaAero"}} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_${treeStyle}_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAOCAYAAAAWo42rAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAZElE
QVQoU2P4//8/A1GApgotgZgbwsQCkBRGAHE4EAuDeegATaEoEKcAsTRIAAUgK4SyQSbmA7EqiAMH
6AqhfAkgrgViQRAHDLCYKATE+E0EYhEgJuxGICbK10SHI35AnEIGBgDfPzypQe1LowAAAABJRU5E
rkJggg==
"
	tablelist_${treeStyle}_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAOCAYAAAAWo42rAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAASklE
QVQoU2P4//8/A1Fg8Cl0BOJyCBMKsCgEKboCxDfBPBhAUwhWFBERARLEqRCuCJ9CFEX4FIIcDpJA
xpVAjABYPIMdDJRCBgYA0sVCxaUivcEAAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAOCAYAAAAWo42rAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAY0lE
QVQoU2P4//8/A1GAdgpljnyfAsSGYA42gKTwExBfB2JnsAA6QFNYAMQvgTgSLIgMkBWC2EA6CYi/
gWiwBAygK4QqTgfi/0CsAZYEAbJMBGLi3AjERPmauHAkCIhTyMAAAJhFf793qI06AAAAAElFTkSu
QmCC
"
	tablelist_${treeStyle}_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAOCAYAAAAWo42rAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAARklE
QVQoU2P4//8/A1FgkCmUOfK9Eog3QrkQgK4Qqug3EKNKICuEKWq6//s/ToXIinAqRFeET+FGkAQa
xu8ZnGCgFDIwAAAYyHMZpMy2ogAAAABJRU5ErkJggg==
"
    } else {
	tablelist_${treeStyle}_collapsedImg put "
R0lGODlhCgAOAMIHAAAAAIKCgpCQkJubm6enp6ioqMbGxv///yH5BAEKAAcALAAAAAAKAA4AAAMa
eLrc/szAQwokZzx8hONH0HDemG3WI03skwAAOw==
"
	tablelist_${treeStyle}_expandedImg put "
R0lGODlhCgAOAMIGAAAAACYmJisrK1hYWIaGhoiIiP///////yH5BAEKAAcALAAAAAAKAA4AAAMY
eLrc/jCeAkV4YtyWNR/gphRBGRBSqkoJADs=
"
	tablelist_${treeStyle}_collapsedActImg put "
R0lGODlhCgAOAMIGAAAAABzE9ybG9y/J9z/N+Hvc+v///////yH5BAEKAAcALAAAAAAKAA4AAAMa
eLrc/qzAIwgUZzxMHT9Bw30LpnnWI03skwAAOw==
"
	tablelist_${treeStyle}_expandedActImg put "
R0lGODlhCgAOAMIEAAAAAB3E92HW+YLf+////////////////yH5BAEKAAAALAAAAAAKAA4AAAMX
CLrc/jACAUN4YdyWNR/gpgiWRUloGiUAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs_125
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs_125 {{treeStyle "vistaAero"}} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_${treeStyle}_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAQCAYAAADNo/U5AAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwQAADsEBuJFr7QAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAfElE
QVQ4T6XSSwqAMAwE0NygYBUP4M4jeBK37l269upx0AgZKdag8NCZNogfUdWwYllTLGs4iEyQfFfC
QWQ2ne+fOFwDGRbo/ZrHAUN2bmCFwa/fONiQXSfYYPR7zjUKbshyCztk6in8uROO2DNB/O2Z0HeK
/xFfFct3Kgd7BgT8X0rnFQAAAABJRU5ErkJggg==
"
	tablelist_${treeStyle}_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAQCAYAAADNo/U5AAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAX0lE
QVQ4T5WLwQ3AIAzEWIWF+GcUBuwQnSaECqQqOTiI5Ed8clLVa6BkQMmAkgHlxC4bJXgvJiN4jDds
XnxyBCLSHx79g6PIBzRCwTZaBSwqfVxQYXQLlAwoGVDu0dQApYwcjGzIaS0AAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAQCAYAAADNo/U5AAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwQAADsEBuJFr7QAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAjElE
QVQ4T5XSzQ1AQBAFYIVI1KAGFTi67tVFFSpQkj5cXDTAcbxJduWNbNg5fNl9wyN+KhFxyw7/ZId/
TKjXa4GWZzkmoLDDBh3P30yIpREOGPgYM0FLcQ1wwsTHExNSKe6HZr0E68znKBO4FHMPWgw8fzaK
S9j77qRXhvJnAv/bA/d38v8RpbLDb1LdInxaO2Da/xgAAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAQCAYAAADNo/U5AAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAZUlE
QVQ4T5WQsQ2AMAwEMwhTMVI2yg7swQa0FCmMkbAURx+/Ka74s65xEZHfQMmAkgElA0pjO+5dabN3
Y+QLLkWnv7lhWFDPLqloDFLRHNAIBWG0CljU3uOC/MsjoGRAyYAyRsoDbx1o4rZ56f0AAAAASUVO
RK5CYII=
"
    } else {
	tablelist_${treeStyle}_collapsedImg put "
R0lGODlhDQAQAMIHAAAAAIGBgYuLi5OTk56enqenp8XFxf///yH5BAEKAAcALAAAAAANABAAAAMg
eLrc/tCZuEqh5xJ6z4jdIUDhETzhiCofeWxg+UxYjSUAOw==
"
	tablelist_${treeStyle}_expandedImg put "
R0lGODlhDQAQAMIGAAAAACYmJjo6OllZWYaGhrGxsf///////yH5BAEKAAcALAAAAAANABAAAAMe
eLrc/jDKVqYIUgwM9e5DyDWe6JQmUwRsS0xwLDsJADs=
"
	tablelist_${treeStyle}_collapsedActImg put "
R0lGODlhDQAQAMIHAAAAAB7E9yTG9y/J9zTK9zjL+Hvc+v///yH5BAEKAAcALAAAAAANABAAAAMg
eLrc/tCZuEihh5xB9RGRdwSQOD4iiSpguXUXNWE0lgAAOw==
"
	tablelist_${treeStyle}_expandedActImg put "
R0lGODlhDQAQAMIFAAAAABzE9yvH92HW+YLf+////////////yH5BAEKAAcALAAAAAANABAAAAMe
eLrc/jDKNqYIUhAM9e5EyDWe6JQmMwRsW01wLDcJADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs_150
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs_150 {{treeStyle "vistaAero"}} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_${treeStyle}_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAkklE
QVQ4T63Tqw6AMAwF0GocjwSBIdlv8B84LBKD4evHHVS0S3ltLDmB20JDYJD3PotZ/MIsfqED0QCl
rD3RgWhkjazf0eG8uYIJWtm7ogMG8LGGGTrZt+jAA/g8DFmgl9fEdBADOIchKzhZl3SIBnDNwQZF
3Dv6Kvz5BFjp7wAr/StA3j5gyTsx719IYRbf87QDkkXd7AZZ8UwAAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAaklE
QVQ4T6WM0QnAIAwF3a4zOIl0z/50mjSBBkSukkeF+/D0XjOzX6BUQKmAUgGlAsoZP4cz6C1Ambzx
5dz0HqAMMu69x0UbmGN5YI2lAYrLA19xaWAXB5WBEZ82nGuYoFRAqYBSAWUdaw84XP55BTs9TwAA
AABJRU5ErkJggg==
"
	tablelist_${treeStyle}_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAkklE
QVQ4T6WTuw2AMAxEMwjLsAItJQ0l27AQ81BQQGlsyZF8kSG/4sncmTtFIgQi6sI1a3DNGkAMx7Mz
k/VygODwxZzMbP0/QGjBqnOxuy9ASFCnlNwy7d4DRCzQ51iy2XdSQNgC1dkSEGmBelJCzJjuBBBp
gYbbTlASFkDEAhOu/woabr8HTNdN7PsXWnDNcii8/8FGqvnrvTkAAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAcElE
QVQ4T6WSsQ2AIBQFGcQh7e3ciB1cwziGBcX3k0hCzEn+0+IKDu5VJDP7BUoFlAooFVAqoOyZtnN2
Mt1VUDbuuDh+5DcoKy1e9mLyQB+vhzjwjKUBisMDb3FoYBRHB3J9NODbP4iAUgGlAso4li4fLlnw
8CctEgAAAABJRU5ErkJggg==
"
    } else {
	tablelist_${treeStyle}_collapsedImg put "
R0lGODlhEAASAOMIAAAAAIaGhouLi5CQkJiYmKGhoaioqMPDw///////////////////////////
/////yH5BAEKAAAALAAAAAAQABIAAAQrEMhJq70426OrMd0EFiEAAkR4AkO3AoL2AkH2xvbUylLq
AiTVLMMpGY+ACAA7
"
	tablelist_${treeStyle}_expandedImg put "
R0lGODlhEAASAMIGAAAAACYmJisrK1lZWYaGhoiIiP///////yH5BAEKAAcALAAAAAAQABIAAAMj
eLrc/jDKSWepR4Qqxp6dBw7kB4VlhKbPyjZFIM8Bgd14DiUAOw==
"
	tablelist_${treeStyle}_collapsedActImg put "
R0lGODlhEAASAMIFAAAAABzE9ybG9yvH93jc+v///////////yH5BAEKAAcALAAAAAAQABIAAAMj
eLrc/jA6IpsYdYmzc+8SCELj6JhBVIZa9XlcxmEyJd/4kQAAOw==
"
	tablelist_${treeStyle}_expandedActImg put "
R0lGODlhEAASAMIFAAAAAB3E92HW+Xvd+4Lf+////////////yH5BAEKAAcALAAAAAAQABIAAAMj
eLrc/jDKSaeoJ4Qaxp4d8UWhKJUmhKbOyjKCJmsXZt/4kwAAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs_200
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs_200 {{treeStyle "vistaAero"}} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_${treeStyle}_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAYAAAC0EpUuAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwAAADsABataJCQAAAAd0SU1FB98IEBUWORalREAAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAJNJREFUOE+10zsKgDAQBNCt7fyAhY2Qa3gPO1tLGxtPHye4RdgNJpI1
8DBOwiBqyHtvLhnWSoa1dEC0QCvzL3RAtLJBrpXSwVPYwQajXC+hA5TytYcdJrknRwdcyvNQfMAc
78nRQVTK96H4BBfnb3QgSjlzcEEj11J08PeTYti+Uwzbrw/2/ykzPVH2Z99CMqzj6QYGRertj0pe
+AAAAABJRU5ErkJggg==
"
	tablelist_${treeStyle}_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAYAAAC0EpUuAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwAAADsABataJCQAAAAd0SU1FB98IEBUeBx8d0+MAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAGtJREFUOE+tzMEJwCAQRFG7Sw1biaTPXFLNxoUIi3w9OArv4Ii/uPtx
OKpwVOGowlGF46idq6n0RnDM/uDTvPROcOx60Mziokdz8Eh0DMpRCkrRWXA7ugqG3WiNjwt3/riC
owpHFY4qHDVePsGgC4kbm9dDAAAAAElFTkSuQmCC
"
	tablelist_${treeStyle}_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAYAAAC0EpUuAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwAAADsABataJCQAAAAd0SU1FB98IEBUVIS7kj9UAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAJNJREFUOE+tkzEKgDAMRT2Il/EKro4ujt7GC3keBwcdYwIplPxAW5vh
UX0pj4J2IKJwXNmLK3sBMZ7vwczWtwCCgzdzMYud1QJCo5uuq53XAEJiukr4kdXuKQEiRfU5hfd8
TwkQeVTfm8MgbFSdhImZ7MwDhI1qMO6kf4ICiBTNgjFfX4Ox/ykTfqPi734EruyDhg9wSVOrXMoi
bgAAAABJRU5ErkJggg==
"
	tablelist_${treeStyle}_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAYAAAC0EpUuAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwAAADsABataJCQAAAAd0SU1FB98IEBUbEg+3w00AAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAHJJREFUOE+t0rENgCAURVEGcUh7OzdiB9cwjmFB8cVEEvJzpeD94hQ+
5FYkMwuHowpHFY4qHFU4estxr1WmM4Jj7wuWqn7yPx6OTQtuZ7GQaB/cr4CoD8pRCkrRv+B0dBRU
ovm9OBD3TmfgqMJRhaPG0gNGBmbxSYGdJwAAAABJRU5ErkJggg==
"
    } else {
	tablelist_${treeStyle}_collapsedImg put "
R0lGODlhFQASAOMIAAAAAIaGhouLi5CQkJiYmKGhoaioqMPDw///////////////////////////
/////yH5BAEKAAAALAAAAAAVABIAAAQvEMhJq7046w0Ox4bxWWIxUiJAnFIKDKwLCKcMBKNM5xNc
S6sYwMQChIoSD3LJjAAAOw==
"
	tablelist_${treeStyle}_expandedImg put "
R0lGODlhFQASAMIGAAAAACYmJisrK1lZWYaGhoiIiP///////yH5BAEKAAcALAAAAAAVABIAAAMl
eLrc/jDKSauV5TIRtBJDp4HhOJxiRaLWylLuiwV0HRBeru97AgA7
"
	tablelist_${treeStyle}_collapsedActImg put "
R0lGODlhFQASAMIFAAAAABzE9ybG9yvH93jc+v///////////yH5BAEKAAcALAAAAAAVABIAAAMn
eLrc/jDKeQiFYlwnTt/L94HjeJnmlAYbSoagp6RUR9darFh67y8JADs=
"
	tablelist_${treeStyle}_expandedActImg put "
R0lGODlhFQASAMIFAAAAAB3E92HW+Xvd+4Lf+////////////yH5BAEKAAcALAAAAAAVABIAAAMl
eLrc/jDKSauV4rIQtApDp4GEaJHlhabVyk7uGwlczWVeru96AgA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs {{treeStyle "vistaClassic"}} {
    variable scalingpct
    vistaClassicTreeImgs_$scalingpct $treeStyle
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs_100
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs_100 {{treeStyle "vistaClassic"}} {
    foreach mode {collapsed expanded} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    tablelist_${treeStyle}_collapsedImg put "
R0lGODlhDAAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAMAA4AAAIjnI+pyxMP4QmiWhGm
BTYbWnGV5wjAeWJa2K1m+12wE0XNvRQAOw==
"
    tablelist_${treeStyle}_expandedImg put "
R0lGODlhDAAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAMAA4AAAIgnI+pyxMP4QmiWhHm
tdnQjWnAOIYeaDpop4JsBDfyUgAAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs_125
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs_125 {{treeStyle "vistaClassic"}} {
    foreach mode {collapsed expanded} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    tablelist_${treeStyle}_collapsedImg put "
R0lGODlhDwAQAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAPABAAAAIsnI+pyz0BowwoiIsx
PRaDvBnd9WlVVl7hIwDu+61jC55ezaG4mPXyNHEIhwUAOw==
"
    tablelist_${treeStyle}_expandedImg put "
R0lGODlhDwAQAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAPABAAAAIonI+pyz0BowwoiIsx
PTbnbXTeBT6jVgnAygJCKY7wSab0fFfT5PR+AQA7
"
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs_150
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs_150 {{treeStyle "vistaClassic"}} {
    foreach mode {collapsed expanded} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    tablelist_${treeStyle}_collapsedImg put "
R0lGODlhEgASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAASABIAAAI4nI+py+0Bo4wpiIuz
CFUDzSFW9mXhMWIldhrptV7tYAH2fW8dCe5qL/IAUUKTT8OqTJYzh/NpKAAAOw==
"
    tablelist_${treeStyle}_expandedImg put "
R0lGODlhEgASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAASABIAAAIynI+py+0Bo4wpiIuz
CFV7jlheBh7ieJXGiaqDBcSyvHVoat8uO+43HvrVQpOiy4FMGgoAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs_200
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs_200 {{treeStyle "vistaClassic"}} {
    foreach mode {collapsed expanded} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    tablelist_${treeStyle}_collapsedImg put "
R0lGODlhFwASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAXABIAAAJHnI+pFu0Pmwqi2ovD
xPzqRGHAyH1IeI1AuYlk1qav16q2XZlHePd53cMJdAyOigUyAlawpItJc8qgFuIA1Wmesh1r5PtQ
FAAAOw==
"
    tablelist_${treeStyle}_expandedImg put "
R0lGODlhFwASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAXABIAAAI+nI+pFu0Pmwqi2ovD
xPzqRHXdh4Ritp0oqK5lBcTyDFTkEdK6neo0z2pZbgzhMGUkDkxCJbPlNAJLkapDUQAAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::win7AeroTreeImgs
#------------------------------------------------------------------------------
proc tablelist::win7AeroTreeImgs {} {
    vistaAeroTreeImgs "win7Aero"
}

#------------------------------------------------------------------------------
# tablelist::win7ClassicTreeImgs
#------------------------------------------------------------------------------
proc tablelist::win7ClassicTreeImgs {} {
    vistaClassicTreeImgs "win7Classic"
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs {} {
    variable scalingpct
    win10TreeImgs_$scalingpct
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs_100
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs_100 {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable win10_${mode}Img \
		 [image create photo tablelist_win10_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_win10_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAKCAYAAAC9vt6cAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAExJREFUKFNj+P//P0UYwWBg0AFiB2RJYjCCAdQMxJGkGoLKIcMQTAESDcEuyMAQ
DDVEB5s8MsYUoMQFpGoGYQSDDM0gjGCQlQ7+MwAAiH+aQTbAbFoAAAAASUVORK5CYII=
"
	tablelist_win10_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAKCAYAAAC9vt6cAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAFRJREFUKFNj+P//P0UYqyApGATigbgDh2QHSB6bHAzDFO0H0WgSWMXRMYRAU4zO
x4cRDKgmHx8fEIcozSCMyiHBZhjGFCAQaOgYqyApGKsg8fg/AwClVaMkbFpt/wAAAABJRU5ErkJg
gg==
"
    } else {
	tablelist_win10_collapsedImg put "
R0lGODlhEAAKAMIGAAAAAKampqysrL+/v9LS0tTU1P///////yH5BAEKAAcALAAAAAAQAAoAAAMZ
eLrcS8PJM0KcrV68NGdCUHyURXof+kFkAgA7
"
	tablelist_win10_expandedImg put "
R0lGODlhEAAKAMIHAAAAAEBAQExMTHd3d5+fn6CgoKGhof///yH5BAEKAAcALAAAAAAQAAoAAAMb
eLrc/oyMNsobYSqsHT8fBAZCJi7hqRhq6z4JADs=
"
    }

    tablelist_win10_collapsedActImg put "
R0lGODlhEAAKAMIGAAAAAE7Q+VjS+Xra+5vh/Jri/P///////yH5BAEKAAcALAAAAAAQAAoAAAMZ
eLrcW8PJM0KcrV68NGdCQHyURXof+kFkAgA7
"
    tablelist_win10_expandedActImg put "
R0lGODlhEAAKAMIGAAAAABzE9yjH+FbS+YDb+4Lc+////////yH5BAEKAAcALAAAAAAQAAoAAAMb
eLrc/oyMNsobYSqsHT8fBAZCJi7hqVhq6zoJADs=
"
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs_125
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs_125 {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable win10_${mode}Img \
		 [image create photo tablelist_win10_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_win10_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABoAAAAMCAYAAAB8xa1IAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAF1JREFUOE+9lMEJwDAMA71QJ+gG3aD7D+JK0EKN9QlYCdxDl8eRTyIzt1BHxAGu
v5uiDkTA7Yh1YYppaYhJSaZjUn68IXKq+xWkJDj+F01HSBeGCKnDFCF12H6GjAdLF1EmW/vAagAA
AABJRU5ErkJggg==
"
	tablelist_win10_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABoAAAAMCAYAAAB8xa1IAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAGNJREFUOE+9j4EJwCAMBDNqN3GUjuJosY8Eqf0UqUmFU3MfIoqq/gKVGVCZAdZx
cbLQQI4+lq1iQypOp+E1X6VvzjDPf2FcpqFzvcu9GMONkEfAUwT/xOBSpDC/A5UZUBmPSgPj7VvG
j4QeDgAAAABJRU5ErkJggg==
"
    } else {
	tablelist_win10_collapsedImg put "
R0lGODlhGgAMAMIFAAAAAKamprW1tcTExNLS0v///////////yH5BAEKAAcALAAAAAAaAAwAAAMi
eLrc/ocISJ8Is2p1867dp4UiFQRDaWGqQ7bLCx/yLM1KAgA7
"
	tablelist_win10_expandedImg put "
R0lGODlhGgAMAMIHAAAAAEBAQEFBQWBgYICAgJ+fn6CgoP///yH5BAEKAAcALAAAAAAaAAwAAAMi
eLrc/jDKSct4w9A1wmXdtx0h543gWaKpcLLNCjfEbN9oAgA7
"
    }

    tablelist_win10_collapsedActImg put "
R0lGODlhGgAMAMIGAAAAAE7Q+WfV+mjV+oHc+5ri/P///////yH5BAEKAAcALAAAAAAaAAwAAAMj
eLrc/qcISJ8Is2p1867X8GnhWAUBYVrY6nRuA8fLTCvSfSQAOw==
"
    tablelist_win10_expandedActImg put "
R0lGODlhGgAMAMIGAAAAABzE9z7M+F/U+oDb+4Hc+////////yH5BAEKAAcALAAAAAAaAAwAAAMi
eLrc/jDKSYl4otAlwmXdtx0h543gWaJpcLLNCjfDbN9oAgA7
"
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs_150
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs_150 {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable win10_${mode}Img \
		 [image create photo tablelist_win10_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_win10_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAB8AAAAQCAYAAADu+KTsAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAIZJREFUSEvNlbENgDAMBD0IDQNQswQLsP8gxi8R5OCvkOMQ6YocSOc0iajqNLgU
WZjPJgqRzTiN/f0tm35jJ77DjaEDRGFBFx86AJdFA1AJEHTxIQNQ2UDQxdMHoNJj63BxsLL/vkBl
w9ackyPkoulhwGVBGERRFAb95gc33Jy7/ZElr5rKBVezH+eTfDdNAAAAAElFTkSuQmCC
"
	tablelist_win10_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAB8AAAAQCAYAAADu+KTsAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAJVJREFUSEvFkNkNgCAQRLcvCrAIfqzC9iwNmXiwukPiASvJ43i7YVBJKf0GlV5Q
6UXZiARdqHG37w7rJDJm5sx0bdCgvvWNrP4UjLBduEMfAK96wOc/sE724tMDcFY1U39L2VQCsCp3
+BacD5egGCNkl2Bghf3SLsGAS/uA5sGASoDAnsGAyp08BuZbQaUXVHpBpQ9JFsLONZHqquN4AAAA
AElFTkSuQmCC
"
    } else {
	tablelist_win10_collapsedImg put "
R0lGODlhHwAQAOMIAAAAAKamprOzs8jIyNLS0t7e3uPj4+Tk5P//////////////////////////
/////yH5BAEKAAAALAAAAAAfABAAAAQ3EMhJq7344M0lCUMnUkZghuM4mGCqsqjLrafc0a29CWyh
X7jYbxIcVopGIiw5KdWYk48QCtBAIwA7
"
	tablelist_win10_expandedImg put "
R0lGODlhHwAQAOMJAAAAAEBAQFtbW4mJiZ+fn6CgoLi4uMTExMXFxf//////////////////////
/////yH5BAEKAA8ALAAAAAAfABAAAAQ58MlJq7046807RRnoUUQwXENQjNIRvCeVvgf7zOaEx/Z+
vzmbDigA8oQSHAxp8TGbwafFIK1ar9IIADs=
"
    }

    tablelist_win10_collapsedActImg put "
R0lGODlhHwAQAMIHAAAAAE7Q+WTV+oje+5ri/K3m/bbo/f///yH5BAEKAAcALAAAAAAfABAAAAM0
eLrc/tDASRUJo2pmgs/bNnhYKJKgSY2fWrGlOwlkIT9wei/53vQ+Hiq46LSIi4sOeZAgEwA7
"
    tablelist_win10_expandedActImg put "
R0lGODlhHwAQAOMJAAAAABzE9zjK+GnW+oDb+4Hc+5rh/Kfl/ajl/f//////////////////////
/////yH5BAEKAA8ALAAAAAAfABAAAAQ58MlJq7046807RRnoUUQwXENQjNIRvCeVvgf7zOaEx/Z+
vzmbDigA8oQSHAxp8TGbwafFIK1ar9IIADs=
"
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs_200
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs_200 {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable win10_${mode}Img \
		 [image create photo tablelist_win10_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_win10_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAACgAAAASCAYAAAApH5ymAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAJJJREFUSEvV1rENwCAMRFEGykDZfxGHKyyh45fYIpFe8+PiSkZEoPk91LtxnOOm
V+h/pz0s45LfdOJoA4XuOmAUHyh0Vw1j8oFCd5Uwrnyg0F0VjM4HCt1VwEh8oNDdaRiJjxO6Ow2j
82FCdxUwrnyY0F0VjMmHCd1Vwig+TOiuGsdLxskefvJYuPe5lTSSeq8YH+NamKxWvX/LAAAAAElF
TkSuQmCC
"
	tablelist_win10_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAACgAAAASCAYAAAApH5ymAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAJFJREFUSEvNzgEKgCAMhWFv2k272nKItdZvWDRa8Ik9J74iIqlhmAmGmRybUhZ7
MOPNnafaUh+qVuUHRvp8FVpSv71cR4OWn6/CSrbl+uCwpJ9TNPeVYzPxsD9XfuZr55+bAj5X9m6U
awBFiL8XhUMoZNGdKBgqX6qj2UgYdn+XUxhaf5ZTGGaCYSYYZoJhHlI2JrC2jqb+LJ4AAAAASUVO
RK5CYII=
"
    } else {
	tablelist_win10_collapsedImg put "
R0lGODlhKAASAMIHAAAAAKampqenp6ioqNLS0tPT09TU1P///yH5BAEKAAcALAAAAAAoABIAAANB
eLq1/jDKV4KYOEMT+tUgJnRWaEajd67LQH7s6ZLxOne1TAZ5ePO9zC8o3BExN9gRklxKUiUnpKKS
RghR61W7SAAAOw==
"
	tablelist_win10_expandedImg put "
R0lGODlhKAASAMIGAAAAAEBAQEJCQp+fn6CgoKGhof///////yH5BAEKAAcALAAAAAAoABIAAAM/
eLrc/jDKSau9qlCN4QiCJARE5xBBGj5jyplLCzryCjM1ns43va+5HusXFA53KqMIaVNCWk3nMyqt
Wq/YrCUBADs=
"
    }

    tablelist_win10_collapsedActImg put "
R0lGODlhKAASAMIFAAAAAE7Q+VHQ+Zrh/Jri/P///////////yH5BAEKAAcALAAAAAAoABIAAAM9
eLqz/jDKN4KYOMMarP6Z0HlgCYndZa4K2rGsG8CrTJv2/eU6xveSH/A0mg2DI9WRmFpGOCQnhBCV
Tq2LBAA7
"
    tablelist_win10_expandedActImg put "
R0lGODlhKAASAMIEAAAAAB3E94Db+4Hc+////////////////yH5BAEKAAAALAAAAAAoABIAAAM6
CLrc/jDKSau9alCNoQiBBHIdM4AghAZkqaxhA7vOvNi0vL57/sA4Xw0YE6qCxh8qSUkxn9CodFpK
AAA7
"
}

#------------------------------------------------------------------------------
# tablelist::winnativeTreeImgs
#------------------------------------------------------------------------------
proc tablelist::winnativeTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable winnative_${mode}Img \
		 [image create photo tablelist_winnative_${mode}Img]
    }

    tablelist_winnative_collapsedImg put "
R0lGODlhDwAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAPAA4AAAImnI+pyz0BY1RB2CsC
veDqVFmd9SEVgKLZJnqsMK4g5oKS5OS6UQAAOw==
"
    tablelist_winnative_expandedImg put "
R0lGODlhDwAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAPAA4AAAIjnI+pyz0BY1RB2CsC
xVenymUbQJLiF54IyHlr6h7S7NS2UQAAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::winxpBlueTreeImgs
#------------------------------------------------------------------------------
proc tablelist::winxpBlueTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable winxpBlue_${mode}Img \
		 [image create photo tablelist_winxpBlue_${mode}Img]
    }

    tablelist_winxpBlue_collapsedImg put "
R0lGODlhDwAOAIQeAAAAAHiYtbDC08C3psG4p8K4qMO6qsa+rs/Iu9LMv9LMwNbRxtjTydvWzNzY
z9/b0uPg2eTh2eXh2urp4+3t5/Hw6/Dw7PLy7vX18ff28/b29Pf39fz8+vz8+////////yH5BAEK
AB8ALAAAAAAPAA4AAAVK4CeOZGmeaPoJQesGghl4dO0FcqcDHZfhpcBmowFoKhIgKYABOJ0P5Shw
sVAAE0hDKgpEHAzAQoHgfgKJQ4FAGBjMrFcrpqrbPyEAOw==
"
    tablelist_winxpBlue_expandedImg put "
R0lGODlhDwAOAKUgAAAAAHiYtbDC08C3psG4p8K4qMO6qsa+rs/Iu9LMv9LMwNbRxtfSx9jTydvW
zNzYz9/b0uPg2eTh2eXh2urp4+zr5u3t5/Hw6/Dw7PLy7vX18ff28/b29Pf39fz8+vz8+///////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAAPAA4AAAZPwJ9w
SCwaj8jkTxBoOgMCYwBErYIC0o9W69lgi4FOh0O+TL7EgAbAZkPQw0AGY6lQIg64MCB5NBgLCgh6
PwEJBwUEBAMGhExPTVFKk5Q/QQA7
"
}

#------------------------------------------------------------------------------
# tablelist::winxpOliveTreeImgs
#------------------------------------------------------------------------------
proc tablelist::winxpOliveTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable winxpOlive_${mode}Img \
		 [image create photo tablelist_winxpOlive_${mode}Img]
    }

    tablelist_winxpOlive_collapsedImg put "
R0lGODlhDwAOAIQdAAAAAI6ZfcC3psG4p8K4qMO6qsa+rs/Iu9LMv9LMwNbRxtjTydvWzNzYz9/b
0uPg2eTh2eXh2urp4+3t5/Hw6/Dw7PLy7vX18ff28/b29Pf39fz8+vz8+////////////yH5BAEK
AB8ALAAAAAAPAA4AAAVH4CeOZGmeaCoGbBucQSfP3VsGXA5wG2aTAY0mA8hQIr9R4AJoNh3JlaUy
AUgejOgnAGksAIrEQRtAGAiDgaCg3bpYqrh8FAIAOw==
"
    tablelist_winxpOlive_expandedImg put "
R0lGODlhDwAOAKUfAAAAAI6ZfcC3psG4p8K4qMO6qsa+rs/Iu9LMv9LMwNbRxtfSx9jTydvWzNzY
z9/b0uPg2eTh2eXh2urp4+zr5u3t5/Hw6/Dw7PLy7vX18ff28/b29Pf39fz8+vz8+///////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKACAALAAAAAAPAA4AAAZLQJBw
SCwaj8ikMMBsBo6Bj3T6eRYDnmy2o7ESAxzOZmyReIeBDGC9fpyXmEuFMoE03qBAxMFYKBIHeAEI
BgQDAwIFeHlOTEqPkENBADs=
"
}

#------------------------------------------------------------------------------
# tablelist::winxpSilverTreeImgs
#------------------------------------------------------------------------------
proc tablelist::winxpSilverTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable winxpSilver_${mode}Img \
		 [image create photo tablelist_winxpSilver_${mode}Img]
    }

    tablelist_winxpSilver_collapsedImg put "
R0lGODlhDwAOAIQXAAAAAJSVosTO2MXP2cbO2svT3NPZ4tXb5Nnf5trg593i6d/l6uDm6+bq7ufr
7+zv8+/y9PLz9vT39/b3+ff4+vn6+v39/f///////////////////////////////////yH5BAEK
AB8ALAAAAAAPAA4AAAVF4CeOZGmeaCoGbBucwSXP11sGVg7klE0GlQoFQIk4fKPABMBkMpArSQQC
eDQU0E+gsUgAEAdDNnAoDM4CQlbrYqne8FEIADs=
"
    tablelist_winxpSilver_expandedImg put "
R0lGODlhDwAOAIQYAAAAAJSVosTO2MXP2cbO2svT3NPZ4tXb5Nnf5trg593i6d/l6uDm6+bq7ufr
7+zv8+/x8+/y9PLz9vT39/b3+ff4+vn6+v39/f///////////////////////////////yH5BAEK
AB8ALAAAAAAPAA4AAAVD4CeOZGmeaCoGbBucASbP2FsGV65XNhlYlopQ4uiNAhSAUskwriaSCOTR
UDg/gcYikUAcDNfAoTAoCwhXrIulartHIQA7
"
}

#------------------------------------------------------------------------------
# tablelist::yuyoTreeImgs
#------------------------------------------------------------------------------
proc tablelist::yuyoTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable yuyo_${mode}Img \
		 [image create photo tablelist_yuyo_${mode}Img]
    }

    tablelist_yuyo_collapsedImg put "
R0lGODlhDwAOAOMKAAAAAIiKhby9ur7AvMDBvsrMyd3e3eHi4OHi4f7+/v//////////////////
/////yH5BAEKAA8ALAAAAAAPAA4AAARA8MlJq72zjM1HqQWSKCSZIN80jORRJgM1lEpAxyptl7g0
E4Fg0KDoPWalHcmIJCmLMpZC8DKGpCYUqMNJYb6PCAA7
"
    tablelist_yuyo_expandedImg put "
R0lGODlhDwAOAOMIAAAAAIiKhb7AvMDBvsrMyd3e3eHi4f7+/v//////////////////////////
/////yH5BAEKAA8ALAAAAAAPAA4AAAQ58MlJq72TiM0FqYRxICR5GN8kjGV5CJTQzrA6t7UkD0Hf
F4jcQ3YjCYnFI2v2ooSWJhSow0lhro8IADs=
"
}

#------------------------------------------------------------------------------
# tablelist::createTreeImgs
#------------------------------------------------------------------------------
proc tablelist::createTreeImgs {treeStyle depth} {
    set baseWidth  [image width  tablelist_${treeStyle}_collapsedImg]
    set baseHeight [image height tablelist_${treeStyle}_collapsedImg]

    #
    # Get the width of the images to create for the specified depth and
    # the destination x coordinate for copying the base images into them
    #
    set width [expr {$depth * $baseWidth}]
    set x [expr {($depth - 1) * $baseWidth}]
    if {[string compare $treeStyle "win10"] == 0} {
	variable scalingpct
	switch $scalingpct {
	    100 { set factor -8 }
	    125 { set factor -16 }
	    150 { set factor -19 }
	    200 { set factor -24 }
	}
    } elseif {[regexp {^(vistaAero|win7Aero)$} $treeStyle]} {
	variable scalingpct
	switch $scalingpct {
	    100 { set factor  0 }
	    125 { set factor -3 }
	    150 { set factor -6 }
	    200 { set factor -11 }
	}
    } elseif {[regexp {^(vistaClassic|win7Classic)$} $treeStyle]} {
	variable scalingpct
	switch $scalingpct {
	    100 { set factor -2 }
	    125 { set factor -5 }
	    150 { set factor -8 }
	    200 { set factor -13 }
	}
    } elseif {[regexp {^(mate|ubuntu)$} $treeStyle]} {
	set factor -2
    } elseif {[regexp {^mint2$} $treeStyle]} {
	set factor -1
    } elseif {[regexp \
	    {^plastik$} $treeStyle]} {
	set factor 2
    } elseif {[regexp \
	    {^plastique$} $treeStyle]} {
	set factor 3
    } elseif {[regexp \
	    {^(baghira|klearlooks|oxygen.|phase|plasti.+|winnative|winxp.+)$} \
	    $treeStyle]} {
	set factor 4
    } else {
	set factor 0
    }
    set delta [expr {($depth - 1) * $factor}]
    incr width $delta
    incr x $delta

    foreach mode {indented collapsed expanded} {
	image create photo tablelist_${treeStyle}_${mode}Img$depth \
	    -width $width -height $baseHeight
    }

    foreach mode {collapsed expanded} {
	tablelist_${treeStyle}_${mode}Img$depth copy \
	    tablelist_${treeStyle}_${mode}Img -to $x 0

	foreach modif {Sel Act SelAct} {
	    variable ${treeStyle}_${mode}${modif}Img
	    if {[info exists ${treeStyle}_${mode}${modif}Img]} {
		image create photo \
		    tablelist_${treeStyle}_${mode}${modif}Img$depth \
		    -width $width -height $baseHeight
		tablelist_${treeStyle}_${mode}${modif}Img$depth copy \
		    tablelist_${treeStyle}_${mode}${modif}Img -to $x 0
	    }
	}
    }
}
