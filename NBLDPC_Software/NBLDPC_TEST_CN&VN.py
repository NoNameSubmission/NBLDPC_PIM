import numpy as np


class CheckNode:
    def __init__(self, CheckDegree, Field, ASTable, MulTable, VariBit, CheckBit):
        self.CheckDegree = CheckDegree
        self.Field = Field
        self.ASTable = ASTable
        self.MulTable = MulTable
        self.FinalLLR = np.zeros((self.CheckDegree, self.Field), dtype=int)
        self.CheckBit = CheckBit
        self.VariBit = VariBit

    def Receive(self, VariLLR, CheckMul):
        """
        :param VariLLR: V2C Messages, [CheckDegree, GF Field]
        :param CheckMul: H Matrix Row Vector [CheckDegree]
        """
        InitLLR = np.zeros(VariLLR.shape, dtype=int)  # 2bit
        for i in range(self.CheckDegree):
            for j in range(self.Field):
                TempIndex = self.MulTable[j][CheckMul[i]]
                InitLLR[i][TempIndex] = VariLLR[i][j]
        # InitLLR = InitLLR.min(initial=0)
        LLR_Forward = np.zeros((self.CheckDegree - 1, self.Field), dtype=int)   # 4bit
        LLR_Backward = np.zeros((self.CheckDegree - 1, self.Field), dtype=int)  # 4bit
        LLR_Forward[0] = InitLLR[0].copy()
        LLR_Backward[-1] = InitLLR[-1].copy()
        for i in range(1, self.CheckDegree - 1):
            LLR_Forward[i] = PassLLR(LLR_Forward[i - 1], InitLLR[i], self.ASTable)
            LLR_Backward[self.CheckDegree - 2 - i] = \
                PassLLR(LLR_Backward[self.CheckDegree - 1 - i], InitLLR[self.CheckDegree - 1 - i], self.ASTable)
            # if i == self.CheckDegree / 2 - 2:
            #     LLR_Forward[i] -= 20
            #     LLR_Backward[self.CheckDegree - 2 - i] -= 16
        for i in range(self.CheckDegree):
            if i == 0:
                TempLLR = np.clip(LLR_Backward[i], -2 ** (self.CheckBit - 1), 2 ** (self.CheckBit - 1) - 1)  # 3bit
            elif i == self.CheckDegree - 1:
                TempLLR = np.clip(LLR_Forward[i - 1], -2 ** (self.CheckBit - 1), 2 ** (self.CheckBit - 1) - 1)  # 3bit
            else:
                TempLLR = np.clip(PassLLR(LLR_Forward[i - 1], LLR_Backward[i], self.ASTable), -2 ** (self.CheckBit - 1),
                                  2 ** (self.CheckBit - 1) - 1)
                # 3bit
            self.FinalLLR[i] = TempLLR
        File = open("./DATA/MIDOUT_CHECK_DATA.txt", "a")
        for i in range(self.CheckDegree):
            for j in range(self.Field):
                print(self.FinalLLR[i][j], file=File, end=' ')
            print(file=File)
        print(file=File)
        File.close()
        # for VariIndex in range(self.CheckDegree):
        #     Output = self.FinalLLR[VariIndex].copy()
        #     Output -= Output[0]
        #     Temp = Output.max()
        #     TargetPlace = 0
        #     while Temp >= 1:
        #         TargetPlace += 1
        #         Temp = Output.max() >> TargetPlace
        #     TargetPlace -= self.VariBit
        #     if TargetPlace >= 0:
        #         Output >>= TargetPlace
        #     self.FinalLLR[VariIndex] = Output
        File = open("./DATA/QUANTOUT_CHECK_DATA.txt", "a")
        for i in range(self.CheckDegree):
            for j in range(self.Field):
                print(self.FinalLLR[i][j], file=File, end=' ')
            print(file=File)
        print(file=File)
        File.close()
        for i in range(self.CheckDegree):
            TempLLR = self.FinalLLR[i].copy()
            for j in range(self.Field):
                TempIndex = np.where(self.ASTable[j] == 0)[0]
                self.FinalLLR[i][TempIndex] = TempLLR[j]  # 4bit
        File = open("./DATA/TRUEOUT_CHECK_DATA.txt", "a")
        for i in range(self.CheckDegree):
            for j in range(self.Field):
                print(self.FinalLLR[i][j], file=File, end=' ')
            print(file=File)
        print(file=File)
        File.close()
        for i in range(self.CheckDegree):
            temp = self.FinalLLR[i].copy()
            for j in range(self.Field):
                Inv = np.where(self.MulTable[CheckMul[i]] == j)[0]
                self.FinalLLR[i][Inv] = temp[j]  # 2bit
        File = open("./DATA/INPUT_CHECK_DATA.txt", "a")
        for i in range(self.CheckDegree):
            for j in range(self.Field):
                print(VariLLR[i][j], file=File, end=' ')
            print(file=File)
        print(file=File)
        File.close()
        File = open("./DATA/MATRIX_CHECK_DATA.txt", "a")
        for i in range(self.CheckDegree):
            print(CheckMul[i], file=File, end=' ')
        print(file=File)
        File.close()
        File = open("./DATA/INIT_CHECK_DATA.txt", "a")
        for i in range(self.CheckDegree):
            for j in range(self.Field):
                print(InitLLR[i][j], file=File, end=' ')
            print(file=File)
        print(file=File)
        File.close()
        File = open("./DATA/FORWARD_CHECK_DATA.txt", "a")
        for i in range(self.CheckDegree - 1):
            for j in range(self.Field):
                print(LLR_Forward[i][j], file=File, end=' ')
            print(file=File)
        print(file=File)
        File.close()
        File = open("./DATA/BACKWARD_CHECK_DATA.txt", "a")
        for i in range(self.CheckDegree - 1):
            for j in range(self.Field):
                print(LLR_Backward[i][j], file=File, end=' ')
            print(file=File)
        print(file=File)
        File.close()
        File = open("./DATA/OUTPUT_CHECK_DATA.txt", "a")
        for i in range(self.CheckDegree):
            for j in range(self.Field):
                print(self.FinalLLR[i][j], file=File, end=' ')
            print(file=File)
        print(file=File)
        File.close()

    def Send(self, VariIndex):
        return self.FinalLLR[VariIndex]


class VariNode:
    def __init__(self, VariDegree, Field, ASTable, MulTable, Prior, VariBit):
        self.VariDegree = VariDegree
        self.Field = Field
        self.ASTable = ASTable
        self.MulTable = MulTable
        self.Prior = Prior.copy()
        self.LLR = Prior.copy()
        self.VariBit = VariBit

    def Receive(self, CheckLLR):
        """
        :param CheckLLR: C2V Messages, [VariDegree, GF Field]
        """
        File = open("./DATA/INPUT_VARIABLE_DATA.txt", "a")
        for i in range(self.VariDegree):
            for j in range(self.Field):
                print(CheckLLR[i][j], file=File, end=' ')
            print(file=File)
        print(file=File)
        File = open("./DATA/PRIOR_VARIABLE_DATA.txt", "a")
        for j in range(self.Field):
            print(self.Prior[j], file=File, end=' ')
        print(file=File)
        File.close()
        previousLLR = self.LLR.copy()
        self.LLR = self.Prior.copy()
        TEMP_LLR = np.zeros(self.Field, dtype=int)
        for i in range(self.VariDegree):
            TEMP_LLR += CheckLLR[i]  # 2bit
        File = open("./DATA/MIDOUT_VARIABLE_DATA.txt", "a")
        for j in range(self.Field):
            print(TEMP_LLR[j], file=File, end=' ')
        print(file=File)
        File.close()
        self.LLR += TEMP_LLR
        # self.LLR = np.clip(self.LLR, -8, 7)
        File = open("./DATA/BUFOUT_VARIABLE_DATA.txt", "a")
        for j in range(self.Field):
            print(self.LLR[j], file=File, end=' ')
        print(file=File)
        File.close()
        self.LLR -= self.LLR[0]
        Temp = self.LLR.copy()
        FLAG = True
        TargetPlace = 0
        while FLAG:
            TargetPlace += 1
            Temp >>= 1
            FLAG = False
            for item in Temp:
                if item != 0 and item != -1:
                    FLAG = True
        # Temp = max(abs(self.LLR))
        # TargetPlace = 0
        # while Temp >= 1:
        #     TargetPlace += 1
        #     Temp >>= 1
        TargetPlace -= self.VariBit
        # # print(TargetPlace)
        if TargetPlace > 0:
            self.LLR >>= TargetPlace
        File = open("./DATA/OUTPUT_VARIABLE_DATA.txt", "a")
        for j in range(self.Field):
            print(self.LLR[j], file=File, end=' ')
        print(file=File)
        File.close()

    def Send(self):
        return self.LLR

    def Output(self):
        return np.argmax(self.LLR)


def PassLLR(LLRA, LLRB, ASTable):
    Field = len(LLRA)
    LLRO = np.ones(Field, dtype=int) * -100
    for i in range(Field):
        for j in range(Field):
            LLRO[ASTable[i][j]] = max(LLRA[i] + LLRB[j], LLRO[ASTable[i][j]])
    LLRO -= LLRO[0]
    return LLRO


def DefaultTable(States=2):
    ASTable = np.zeros((States, States), dtype=int)
    for i in range(States):
        for j in range(States):
            ASTable[i][j] = (i + j) % States
    MulTable = np.zeros((States, States), dtype=int)
    for i in range(States):
        for j in range(States):
            MulTable[i][j] = (i * j) % States
    BinaryBits = int(np.ceil(np.log2(States)))
    GFField = np.zeros((States, BinaryBits), dtype=int)
    for i in range(States):
        for j in range(BinaryBits - 1, -1, -1):
            GFField[i][j] = (i >> j) & 1
    return ASTable, MulTable, GFField


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


def GFMatMul(M1, M2, ASTable, MulTable):
    Left, Middle = M1.shape
    Middle, Right = M2.shape
    Output = np.zeros((Left, Right), dtype=int)
    for i in range(Left):
        for j in range(Right):
            for k in range(Middle):
                Temp = MulTable[M1[i][k]][M2[k][j]]
                Output[i][j] = ASTable[Temp][Output[i][j]]
    return Output


def Decode(IterLim, LLRV, ASTable, MulTable, H, Field, File, CheckDegree, VariDegree):
    """
    :param File:    Output File
    :param IterLim: int Maximum Iterating Times
    :param LLRV:    np.array [SymbolNum, Bit Per Symbol]
    :param ASTable: np.array [Max Value, Max Value] Add and Sub Look up Table
    :param MulTable: np.array [Max Value, Max Value] Multiply Look up Table
    :param H: np.array [CheckNodeNum, Total Symbol Num] Check Matrix
    :param Field: State Num
    :param CheckDegree: Number of Variable Nodes connect to a Check Node
    :param VariDegree: Number of Check Nodes connect to a Variable Node
    :return: OutSymbol np.array [Total Symbol Num] Decoding Result in GF pattern
    """
    CheckNum, VariNum = H.shape
    CheckList = []
    VariList = []
    Pass = False
    it = 0
    OutSymbol = np.zeros(VariNum, dtype=int)
    for i in range(CheckNum):
        CheckList.append(CheckNode(CheckDegree, Field, ASTable, MulTable, 2, 4))
    for i in range(VariNum):
        VariList.append(VariNode(VariDegree, Field, ASTable, MulTable, LLRV[i], 2))
    for it in range(IterLim):
        print("*", it, "*")
        OutSymbol = np.zeros(VariNum, dtype=int)
        for i in range(CheckNum):
            LLR = []
            CheckMul = []
            for j in range(VariNum):
                if H[i][j] == 0:
                    continue
                LLR.append(VariList[j].Send())
                CheckMul.append(H[i][j])
            CheckList[i].Receive(np.vstack(LLR).copy(), np.array(CheckMul, dtype=int).copy())
        RowCount = np.zeros(CheckNum, dtype=int)
        for i in range(VariNum):
            LLR = []
            for j in range(CheckNum):
                if H[j][i] == 0:
                    continue
                LLR.append(CheckList[j].Send(RowCount[j]))
                RowCount[j] += 1
            VariList[i].Receive(np.vstack(LLR).copy())
            OutSymbol[i] = VariList[i].Output().item()
        OutSymbol = OutSymbol.reshape((1, VariNum))
        CheckResult = GFMatMul(OutSymbol, H.transpose(), ASTable, MulTable)
        Index = np.where(CheckResult != 0)[1]
        if len(Index) == 0:
            Pass = True
            # break
    return Pass, OutSymbol, it


def NoiseGeneration(Error, CheckLength, InfoLength, Field, RowAdd):
    InfoNoiseNum = np.random.randint(0, Error + 1)
    CheckNoiseNum = Error - InfoNoiseNum
    InfoNoise = np.zeros((RowAdd, InfoLength), dtype=int)
    InfoNoiseColIndex = np.random.randint(0, InfoLength, InfoNoiseNum)
    InfoNoiseRowIndex = np.random.randint(0, RowAdd, InfoNoiseNum)
    InfoNoise[InfoNoiseRowIndex, InfoNoiseColIndex] = 1
    CheckBit = int(np.ceil(np.log2(Field)))
    CheckNoise = np.zeros((RowAdd, int(CheckLength * CheckBit)), dtype=int)
    CheckNoiseColIndex = np.random.randint(0, CheckLength * CheckBit, CheckNoiseNum)
    CheckNoiseRowIndex = np.random.randint(0, RowAdd, CheckNoiseNum)
    CheckNoise[CheckNoiseRowIndex, CheckNoiseColIndex] = 1
    return np.append(InfoNoise, CheckNoise, axis=1)


def GaussNoise(Input, EbNo, RowAdd):
    SNR = (10 ** (EbNo / 10)) * np.log2(RowAdd + 1)
    ADCSNR = ((RowAdd + 1) ** 2) * 3 / 2
    Percent = (ADCSNR - SNR - 1) / (ADCSNR * SNR)
    Noise = np.random.normal(1, Percent, Input.shape)
    Output = Input * Noise
    return Output


def GFToBinary(Input, Field, CheckLength, InfoLength):
    """
    :param Input: np.array [ArrayNum, CheckLength + InfoLength]
    :param Field: States Number
    :param CheckLength: Check Bit Length
    :param InfoLength: Information Bit Length
    :return: Binary Input Code
    """
    CheckBit = np.ceil(np.log2(Field))
    InfoPart = Input[:, :InfoLength].copy()
    CheckPart = np.zeros((Input.shape[0], int(CheckLength * CheckBit)), dtype=int)
    for item in range(Input.shape[0]):
        for i in range(CheckLength):
            Temp = Input[item, i + InfoLength]
            for j in range(int(CheckBit - 1), -1, -1):
                Bit = Temp & 1
                CheckPart[item, int(CheckBit * i + j)] = Bit
                Temp >>= 1
    return np.append(InfoPart, CheckPart, axis=1)


def BinaryToGF(BinaryInput, Field, CheckLenght, InfoLength):
    InfoPart = BinaryInput[:, :InfoLength]
    CheckPart = np.zeros((BinaryInput.shape[0], CheckLenght), dtype=int)
    CheckBit = int(np.ceil(np.log2(Field)))
    for item in range(BinaryInput.shape[0]):
        for i in range(CheckLenght):
            Temp = 0
            for j in range(CheckBit):
                Temp <<= 1
                Temp += BinaryInput[item, CheckBit * i + InfoLength + j]
            CheckPart[item, i] = Temp
    return np.append(InfoPart, CheckPart, axis=1)


def Recur(Field, RowAdd, TempArray, FinalList, Past):
    if RowAdd == 0:
        FinalList.append(TempArray.copy())
        return
    for i in range(Past, Field):
        TempArray.append(i)
        Recur(Field, RowAdd - 1, TempArray, FinalList, i)
        TempArray.pop(-1)
    return


def GeneratePossibleCheck(CheckBit, RowAdd, Field):
    CheckPoss = []
    Recur(Field, RowAdd, [], CheckPoss, 0)
    PossibleList = np.zeros((len(CheckPoss), CheckBit), dtype=int)
    for Comb in range(len(CheckPoss)):
        for item in CheckPoss[Comb]:
            Temp = item
            for j in range(CheckBit):
                PossibleList[Comb, CheckBit - 1 - j] += Temp & 1
                Temp >>= 1
    return PossibleList


def SymbolToLLR(LLR, Symbol, Field, Delta, RowAdd, i):
    LLR[i, Symbol % Field] = (Field - 1) * Delta
    Count = 1
    j = 1
    # while Count < Field and j < Field:
    #     if Symbol + j <= RowAdd:
    #         LLR[i, (Symbol + j) % Field] = (Field - j - 1) * Delta
    #         Count += 1
    #     if Symbol - j >= 0:
    #         LLR[i, (Symbol - j) % Field] = (Field - j - 1) * Delta
    #         Count += 1
    #     j += 1
    return LLR


def GenerateLLR(Word, CodeLength, Field, Delta, InfoLength, RowAdd):
    LLR = np.zeros((CodeLength, Field), dtype=int)
    GFWord = np.zeros((1, CodeLength), dtype=int)
    CheckBit = int(np.ceil(np.log2(Field)))
    for i in range(InfoLength):
        Symbol = Word[0, i].copy()
        GFWord[0, i] = Symbol % Field
        LLR = SymbolToLLR(LLR, Symbol, Field, Delta, RowAdd, i)
    # for i in range(InfoLength, CodeLength):
    PossCheckList = GeneratePossibleCheck(CheckBit, RowAdd, Field)
    for i in range(CodeLength - InfoLength):
        TempSymbol = Word[0, CheckBit * i + InfoLength: CheckBit * (i + 1) + InfoLength]
        if TempSymbol not in PossCheckList:
            Diff = np.zeros(len(PossCheckList))
            for j in range(len(PossCheckList)):
                Diff[j] = np.abs(PossCheckList[j, :] - TempSymbol).sum(axis=0)
            Target = Diff.min(initial=Field * 2)
            Count = 0
            for j in range(len(PossCheckList)):
                if Diff[j] == Target:
                    Count += 1
                    Symbol = 0
                    for k in PossCheckList[j]:
                        Symbol *= 2
                        Symbol += k
                    LLR = SymbolToLLR(LLR, Symbol, Field, Delta, RowAdd, i + InfoLength)
            LLR[i + InfoLength, :] /= Count
        else:
            Symbol = 0
            for j in TempSymbol:
                Symbol *= 2
                Symbol += j
            GFWord[0, i + InfoLength] = Symbol % Field
            LLR = SymbolToLLR(LLR, Symbol, Field, Delta, RowAdd, i + InfoLength)
    return LLR, GFWord


def GFToInt(GFWord, Field, OriginCode, RowAdd, InfoLength):
    Output = np.zeros(GFWord.shape, dtype=int)
    for i in range(InfoLength):
        if GFWord[0, i] == OriginCode[0, i] % Field:
            Output[0, i] = OriginCode[0, i]
        else:
            PlusTemp = OriginCode[0, i]
            MinusTemp = OriginCode[0, i]
            while True:
                if PlusTemp + 1 <= RowAdd:
                    PlusTemp += 1
                if MinusTemp - 1 >= 0:
                    MinusTemp -= 1
                if PlusTemp % Field == GFWord[0, i]:
                    Output[0, i] = PlusTemp
                    break
                elif MinusTemp % Field == GFWord[0, i]:
                    Output[0, i] = MinusTemp
                    break
                elif MinusTemp == 0 and PlusTemp == RowAdd:
                    Output[0, i] = OriginCode[0, i]
                    break
    Output[:, InfoLength:] = GFWord[:, InfoLength:]
    return Output


def IntToBinary(Word, InfoStates, CheckStates, InfoLength, CheckLength):
    InfoBit = int(np.ceil(np.log2(InfoStates)))
    CheckBit = int(np.ceil(np.log2(CheckStates)))
    OutWord = np.zeros(InfoLength * InfoBit + CheckLength * CheckBit, dtype=int)
    for i in range(InfoLength):
        Temp = Word[0, i]
        for j in range(InfoBit):
            OutWord[i * InfoBit + InfoBit - 1 - j] = Temp & 1
            Temp >>= 1
    for i in range(CheckLength):
        Temp = Word[0, i + InfoLength]
        for j in range(CheckBit):
            OutWord[i * CheckBit + CheckBit - 1 - j + InfoLength * InfoBit] = Temp & 1
            Temp >>= 1
    return OutWord


def main():
    # InfoLength = 256
    # CodeRate = 8 / 9
    # CodeLength = int(InfoLength / CodeRate)
    # CheckLength = CodeLength - InfoLength
    CheckLength = 10
    CodeLength = 25
    InfoLength = CodeLength - CheckLength
    CodeRate = InfoLength / CodeLength
    VariDegree = 2
    CheckDegree = int(VariDegree * CodeLength / CheckLength)
    TestLimit = int(1e3)
    ErrorBitNum = 1
    FalseWordNum = 0
    RowAdd = 4
    Field = 3
    IterLim = 3
    InititalDelta = 1
    BUF_PERIOD = 8
    MACRO = 4
    INFO_GROUP = 8
    PARALLEL = 10
    ASTable, MulTable, GFField = DefaultTable(Field)
    # H = ReadMatrix("H_256_8_9_Improved.txt", Shape=(CheckLength, CodeLength))
    # G = ReadMatrix("G_256_8_9_Improved.txt", Shape=(InfoLength, CodeLength))
    # H = ReadMatrix("H_256_8_9.txt", Shape=(CheckLength, CodeLength))
    # G = ReadMatrix("G_256_8_9.txt", Shape=(InfoLength, CodeLength))
    H = ReadMatrix("H_217_Hamilton.txt", Shape=(CheckLength, CodeLength))
    G = ReadMatrix("G_217_Hamilton.txt", Shape=(InfoLength, CodeLength))
    # OutFile = open("Log_256_8_9_test.txt", "w")
    # INPUT_LLR_FILE = open("./DATA/INPUT_LLR_DATA.txt", "a")
    # INPUT_SYMBOL_FILE = open("./DATA/INPUT_SYMBOL_DATA.txt", "a")
    # INPUT_REF_FILE = open("./DATA/INPUT_REF_DATA.txt", "a")
    # INPUT_INFO_FILE = open("./DATA/INPUT_INFO_DATA.txt", "a")
    # OUTPUT_SYMBOL_FILE = open("./DATA/OUTPUT_REF_DATA.txt", "a")
    # OUTPUT_GF_FILE = open("./DATA/OUTPUT_GF_DATA.txt", "a")
    OutFile = open("Log_217_Hamilton.txt", "w")
    INPUT_LLR_FILE = open("./DATA/INPUT_LLR_DATA.txt", "a")
    INPUT_SYMBOL_FILE = open("./DATA/INPUT_SYMBOL_DATA.txt", "a")
    INPUT_REF_FILE = open("./DATA/INPUT_REF_DATA.txt", "a")
    INPUT_INFO_FILE = open("./DATA/INPUT_INFO_DATA.txt", "a")
    OUTPUT_SYMBOL_FILE = open("./DATA/OUTPUT_REF_DATA.txt", "a")
    OUTPUT_GF_FILE = open("./DATA/OUTPUT_GF_DATA.txt", "a")
    FalseCount = 0
    print("NB-LDPC\tCodeLength: {}\tCodeRate: {}".format(CodeLength, CodeRate), file=OutFile)
    for trial in range(TestLimit):
        print(trial)
        print("Iteration\n", trial + 1, file=OutFile)
        EncodeWord = np.random.randint(0, 2, (RowAdd, InfoLength))
        InputWord = GFMatMul(EncodeWord, G, ASTable, MulTable)
        # InputWord = Encode(H, EncodeWord, InfoLength, CheckLength)
        BinaryInputWord = GFToBinary(InputWord, Field, CheckLength, InfoLength)
        SumInputWord = InputWord.sum(axis=0).reshape((1, InputWord.shape[1]))

        SumInputWord[:, InfoLength:] %= Field
        # print("No Wrong Input\n", SumInputWord, file=OutFile)
        Noise = NoiseGeneration(ErrorBitNum, CheckLength, InfoLength, Field, RowAdd)
        NoisyBinaryInput = (BinaryInputWord + Noise) % 2
        NoisySumInput = NoisyBinaryInput.sum(axis=0)
        NoisySumInput = NoisySumInput.reshape((1, NoisyBinaryInput.shape[1]))
        LLRV, NoisyInput = GenerateLLR(NoisySumInput, CodeLength, Field, InititalDelta, InfoLength, RowAdd)
        for i in range(InfoLength):
            print(NoisySumInput[0, i], file=INPUT_REF_FILE)
        for i in range(BUF_PERIOD):
            for k in range(MACRO):
                for j in range(INFO_GROUP):
                    print(NoisySumInput[0, i * INFO_GROUP * MACRO + k * INFO_GROUP + j], file=INPUT_SYMBOL_FILE, end=' ')
                for j in range(INFO_GROUP, PARALLEL):
                    print(NoisySumInput[0, InfoLength + i * (PARALLEL - INFO_GROUP) * MACRO + k * (PARALLEL - INFO_GROUP) + j - INFO_GROUP], file=INPUT_SYMBOL_FILE, end=' ')
                print(file=INPUT_SYMBOL_FILE)
        print(file=INPUT_SYMBOL_FILE)
        for i in range(CodeLength):
            if i < InfoLength:
                print(NoisySumInput[0, i], file=INPUT_INFO_FILE)
            for j in range(Field):
                print(LLRV[i][j], file=INPUT_LLR_FILE, end=' ')
            print(file=INPUT_LLR_FILE)
        # print("Noisy Input\n", NoisyInput, file=OutFile)
        # print("Generate LLR\t", LLRV, file=OutFile)
        # print(InputWord)
        # print(NoisyInput)
        # LLRV /= LLRV.max(initial=0)
        Pass, OutWord, it = Decode(IterLim, LLRV, ASTable, MulTable, H, Field, OutFile, CheckDegree, VariDegree)
        for i in range(InfoLength):
            print(OutWord[0, i], file=OUTPUT_GF_FILE)
        OutWord = GFToInt(OutWord, Field, NoisySumInput, RowAdd, InfoLength)
        for i in range(InfoLength):
            print(OutWord[0, i], file=OUTPUT_SYMBOL_FILE)
        print(Pass, file=OutFile)
        # print("Final Output\n", OutWord, file=OutFile)
        SumInputWord = IntToBinary(SumInputWord, RowAdd + 1, Field, InfoLength, CheckLength)
        if Pass:
            OutWord = IntToBinary(OutWord, RowAdd + 1, Field, InfoLength, CheckLength)
        else:
            NoisyInput = GFToInt(NoisyInput, Field, NoisySumInput, RowAdd, InfoLength)
            # OutWord = IntToBinary(NoisyInput, RowAdd + 1, Field, InfoLength, CheckLength)
            OutWord = IntToBinary(OutWord, RowAdd + 1, Field, InfoLength, CheckLength)
        FalseWord = len(np.where(OutWord != SumInputWord)[0])
        FalseWordNum += FalseWord
        print("Loop: {}\t False: {}\t BER: {} Iteration: {}\n".format(trial + 1, FalseWordNum,
                                                                      FalseWordNum / ((trial + 1) * len(OutWord)), it),
              file=OutFile)
        if FalseWord != 0:
            FalseCount += 1
        # else:
        #     break
        if FalseCount >= 10:
            break
    OutFile.close()
    return


if __name__ == '__main__':
    main()
