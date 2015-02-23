#!/usr/bin/python

# mypath should be the complete path for the directory containing the input text files
#This example taken from here: http://stackoverflow.com/questions/19677104/convert-text-files-to-excel-files-using-python

#mypath = raw_input("Please enter the directory path for the input files: ")
mypath = raw_input("/home/ysboychakov/Documents/DISK IO RESULTS/MY PARSING EFFORTS/SED/12/4.txt")

from os import listdir
from os.path import isfile, join
textfiles = [ join(mypath,f) for f in listdir(mypath) if isfile(join(mypath,f)) and '.txt' in  f]

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False        

import xlwt
import xlrd

style = xlwt.XFStyle()
style.num_format_str = '#,###0.00'  

for textfile in textfiles:
    f = open(textfile, 'r+')
    row_list = []
    for row in f:
        row_list.append(row.split('|'))
    column_list = zip(*row_list)
    workbook = xlwt.Workbook()
    worksheet = workbook.add_sheet('Sheet1')
    i = 0
    for column in column_list:
        for item in range(len(column)):
            value = column[item].strip()
            if is_number(value):
                worksheet.write(item, i, float(value), style=style)
            else:
                worksheet.write(item, i, value)
        i+=1
    workbook.save(textfile.replace('.txt', '.xls'))