import numpy as np


def ReadMatrix(Address, Shape, Type=int):
    f = open(Address, 'r')
    input_string = f.read()
    input_string = input_string.split(' ')
    NumList = []
    for i in range(len(input_string)):
        temp = input_string[i].split('\n')
        for j in range(len(temp)):
            if temp[j] == '':
                continue
            NumList.append(int(temp[j]))
    Mat = np.array(NumList, dtype=Type).reshape(Shape)
    f.close()
    return Mat


def RADIX_TRANS(num, bits, radix=2):
    if num == 0:
        return [0] * bits
    OUT = []
    comp = radix ** (bits - 1)
    while comp >= 1:
        if num >= comp:
            OUT.append(1)
            num -= comp
        else:
            OUT.append(0)
        comp /= radix
    return OUT


def main():
    REF_FILE = open("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/DATA/INPUT_CHECK_DATA.txt")
    CHECK_FILE = open("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/DATA/OUTPUT_SYMBOL_DATA.txt")
    RESTOR_FILE = open("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/DATA/TEST_RESTORE_DATA.txt", "w")
    WRITE_FILE = open("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/DATA/REF.txt", "w")
    REF_STR = REF_FILE.read()
    REF_FIN = REF_STR.split("\n")
    REF_STR = [REF_FIN[i].split(' ') for i in range(len(REF_FIN))]
    REF_FIN = []
    for ROW in REF_STR:
        for ELEMENT in ROW:
            if ELEMENT == "":
                continue
            REF_FIN.append(ELEMENT)
    CHE_STR = CHECK_FILE.read()
    CHE_STR = CHE_STR.split("\n")
    for i in range(len(CHE_STR) - 1):
        if int(CHE_STR[i]) != int(REF_FIN[i]):
            print(i, CHE_STR[i], REF_FIN[i])
    for i in range(len(CHE_STR) - 1):
        print(CHE_STR[i], file=RESTOR_FILE, end=' ')
        if i % 3 == 2:
            print(file=RESTOR_FILE)
        if i % 54 == 53:
            print(file=RESTOR_FILE)
    # H = ReadMatrix("/Users/xxxx/Desktop/Workplace/NBLDPC_TEST/H_256_8_9_Improved.txt", Shape=(32, 288))
    # for i in range(32):
    #     Element = []
    #     for j in range(287, -1, -1):
    #         if H[i][j] != 0:
    #             Element.append(H[i][j])
    #     print("assign H[%d] = {" % i, end='')
    #     for j in range(18):
    #         if Element[j] == 1:
    #             print("2'b01", end='')
    #         elif Element[j] == 2:
    #             print("2'b10", end='')
    #         # print(Element[j], end='')
    #         if j != 17:
    #             print(", ", end='')
    #         else:
    #             print("};")
    # Index = np.zeros((32, 18), dtype=int)
    # for i in range(32):
    #     # print(i, end='\t')
    #     count = 0
    #     for j in range(288):
    #         if H[i][j] != 0:
    #             Index[i][count] = j
    #             count += 1
    #     #         print("%4.d," % j, end='')
    #     # print()
    # for i in range(18):
    #     print("assign LLR_CHECK_INPUT[%d][ckf][cki] = " % i, end='', file=WRITE_FILE)
    # print("assign MAT_CHECK_INPUT[ckf][cki] = ", end='', file=WRITE_FILE)
    #     for j in range(32):
    #         NODE_NUM = RADIX_TRANS(j, 5)
    #         print("(", end='', file=WRITE_FILE)
    #         for k in range(5):
    #             if NODE_NUM[k] == 1:
    #                 print("(NODE_STATE[%d])" % (4 - k), end='', file=WRITE_FILE)
    #             else:
    #                 print("(~NODE_STATE[%d])" % (4 - k), end='', file=WRITE_FILE)
    #             print(" & ", end='', file=WRITE_FILE)
    #         # print("(H[%d][ckf][cki]))" % j, end='', file=WRITE_FILE)
    #         print("(LLR_TRUE_INPUT[%d][ckf][cki]))" % Index[j][i], end='', file=WRITE_FILE)
    #         if j != 31:
    #             print(" | ", end='', file=WRITE_FILE)
    #         else:
    #             print(";", file=WRITE_FILE)
    # VariIndex = np.zeros((288, 2), dtype=int)
    # VariCheckConn = np.zeros((288, 2), dtype=int)
    # Count = np.zeros(288, dtype=int)
    # for i in range(32):
    #     for j in range(18):
    #         VariIndex[Index[i][j]][Count[Index[i][j]]] = j
    #         VariCheckConn[Index[i][j]][Count[Index[i][j]]] = i
    #         Count[Index[i][j]] += 1
    # for i in range(288):
    #     for j in range(2):
    #         print("assign LLR_VARI_INPUT[%d][%d][vf][vi] = LLR_CHECK_STORE[%d][%d][vf][vi];"
    #               % (i, j, VariCheckConn[i][j], VariIndex[i][j]))
    return


if __name__ == '__main__':
    main()
