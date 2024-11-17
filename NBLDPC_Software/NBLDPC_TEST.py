import numpy as np


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


def Decode(Code, IterLim, LLRV, ASTable, MulTable, H, SigScale, Field, File):
    """
    :param File:    Output File
    :param Code:    np.array [TotalBitNum] Input Code
    :param IterLim: int Maximum Iterating Times
    :param LLRV:    np.array [SymbolNum, Bit Per Symbol]
    :param ASTable: np.array [Max Value, Max Value] Add and Sub Look up Table
    :param MulTable: np.array [Max Value, Max Value] Multiply Look up Table
    :param H: np.array [CheckNodeNum, Total Symbol Num] Check Matrix
    :param SigScale: np.float Signal Value of each Vote
    :param Field: State Num
    :return: Pass: bool whether the Check Pass or Not
    :return: OutSymbol np.array [Total Symbol Num] Decoding Result in GF pattern
    """
    CheckNum, SymbolNum = H.shape
    Pass = False
    OutSymbol = Code.copy() % Field
    RowWeight = np.ones(CheckNum, dtype=int) * SigScale
    RowCount = np.zeros(CheckNum, dtype=int)
    VariCount = np.zeros(SymbolNum, dtype=int)
    Experience = np.zeros(SymbolNum, dtype=bool)
    PostLLR_Past = LLRV.copy()
    it = 0
    for it in range(IterLim):
        PostLLR = LLRV.copy()
        for j in range(CheckNum):
            TempVec = H.transpose()[:, j].reshape((SymbolNum, 1))
            for k in range(SymbolNum):
                if TempVec[k][0] == 0:
                    continue
                TempOrigin = OutSymbol.copy()
                TempOrigin[0, k] = 0
                CheckResult = GFMatMul(TempOrigin, TempVec, ASTable, MulTable)[0][0]
                ASInv = np.where(ASTable[CheckResult] == 0)[0][0]
                MulInv = np.where(MulTable[TempVec[k][0]] == ASInv)[0]
                if len(MulInv) != 0:
                    for m in range(SymbolNum):
                        if m == k or TempVec[m][0] == 0:
                            continue
                        PostLLR[k][MulInv[0]] += RowWeight[j] * PostLLR_Past[m][OutSymbol[0, m]]
                    # PostLLR[k][MulInv[0]] += RowWeight[j]
        PostLLR_Past = PostLLR.copy()
        OutSymbol = PostLLR.argmax(axis=1).reshape(1, SymbolNum)
        CheckResult = GFMatMul(OutSymbol, H.transpose(), ASTable, MulTable)
        Index = np.where(CheckResult != 0)[1]
        Count = len(Index)
        # print(PostLLR, file=File)
        # print(PostLLR)
        flag = np.zeros(SymbolNum, dtype=int)
        # for that in Index:
        #     TempIndex = np.where(H[that] != 0)
        #     flag[TempIndex] += 1
        # for that in range(SymbolNum):
        #     if flag[that] != 0:
        #         VariCount[that] += flag[that]
        #     else:
        #         VariCount[that] = 0
        # Index = np.where(VariCount % 2 == 1)[0]
        # if len(Index) != 0:
        #     for that in Index:
        #         MaximumFalse = PostLLR[that].max(initial=0)
        #         Temp = 0
        #         for item in range(ASTable.shape[0]):
        #             if Temp <= PostLLR[that][item] < MaximumFalse and Experience[that] is False:
        #                 OutSymbol[0, that] += 1
        #                 OutSymbol[0, that] %= 3
        #         if Temp != 0:
        #             break
        # for that in range(CheckNum):
        #     if that in Index:
        #         RowCount[that] = 0
        #         RowWeight[that] = SigScale
        #     elif RowCount[that] >= 3:
        #         RowWeight[that] = 0
        #         RowCount[that] = 0
        #     else:
        #         RowCount[that] += 1
        Pass = (Count == 0)
        if Pass:
            break
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
    CheckPart = np.zeros((BinaryInput.shape[0], CheckLenght), dtype=np.int)
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
    LLR[i, Symbol % Field] = Field * Delta
    Count = 1
    j = 1
    while Count < Field and j < Field:
        if Symbol + j <= RowAdd:
            LLR[i, (Symbol + j) % Field] = (Field - j) * Delta
            Count += 1
        if Symbol - j >= 0:
            LLR[i, (Symbol - j) % Field] = (Field - j) * Delta
            Count += 1
        j += 1
    return LLR


def GenerateLLR(Word, CodeLength, Field, Delta, InfoLength, RowAdd):
    LLR = np.zeros((CodeLength, Field))
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


def Encode(GenMat, Info, LenI, LenC, Z=2):
    """
    :param GenMat: [LenC, LenI + LenC] H matrix or generation Matrix
    :param Info: [LenI] Code to encode
    :param LenI: int Information Code Length
    :param LenC: int Check Bit Length
    :param Z: int Unknown about what it means
    :return: Code: [LenI + LenC] Encode Word
    """
    ParityBit = np.mod(np.matmul(GenMat[:, :LenI], Info.transpose()), 2).reshape(LenC)
    CheckBit = np.zeros(LenC, dtype=np.int)
    for i in range(Z):
        for j in range(int(LenC / Z)):
            CheckBit[i] += ParityBit[Z * j + i]
    CheckBit = np.mod(CheckBit, 2)
    ParityBit += np.matmul(GenMat[:, LenI:LenI + Z], CheckBit[:Z])
    ParityBit %= 2
    for i in range(int(len(CheckBit) / Z) - 1):
        CheckBit[(i + 1) * Z:(i + 2) * Z] = ParityBit[i * Z:(i + 1) * Z]
        ParityBit[(i + 1) * Z:(i + 2) * Z] += ParityBit[i * Z:(i + 1) * Z]
        ParityBit %= 2
    CheckBit = np.mod(CheckBit, 2).reshape((1, LenC))
    return np.append(Info, CheckBit, axis=1)


def CheckParity(Code, Mat):
    for i in range(Mat.shape[0]):
        temp = 0
        for j in range(Mat.shape[1]):
            temp += Mat[i][j] * Code[j]
        if temp % 2 != 0:
            print("Fail")
            return False
    return True


def GFToInt(GFWord, Field, OriginCode, RowAdd):
    Output = np.zeros(GFWord.shape, dtype=int)
    for i in range(GFWord.shape[1]):
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
                if MinusTemp % Field == GFWord[0, i]:
                    Output[0, i] = MinusTemp
                    break
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


def GaussNoise(Input, VariationRatio):
    Noise = np.random.normal(1, VariationRatio, Input.shape)
    NoisyInput = Input * Noise
    Output = np.round(NoisyInput.sum(axis=0))
    return Output.astype(int)


def main():
    InfoLength = 256
    CodeRate = 8 / 9
    CodeLength = int(InfoLength / CodeRate)
    CheckLength = CodeLength - InfoLength
    # CheckLength = 36
    # CodeLength = 292
    # InfoLength = CodeLength - CheckLength
    # CodeRate = InfoLength / CodeLength
    TestLimit = int(1e3)
    ErrorBitNum = 1
    FalseWordNum = 0
    RowAdd = 4
    Field = 3
    IterLim = 10
    InititalDelta = 1
    SigScale = 1
    ASTable, MulTable, GFField = DefaultTable(Field)
    H = ReadMatrix("H_256_8_9_Improved.txt", Shape=(CheckLength, CodeLength))
    G = ReadMatrix("G_256_8_9_Improved.txt", Shape=(InfoLength, CodeLength))
    # H = ReadMatrix("H_217_Hamilton.txt", Shape=(CheckLength, CodeLength))
    # G = ReadMatrix("G_217_Hamilton.txt", Shape=(InfoLength, CodeLength))
    OutFile = open("Log_217_Hamilton.txt", "w")
    FalseCount = 0
    Var = 0.1
    # print("NB-LDPC\tCodeLength: {}\tCodeRate: {}".format(CodeLength, CodeRate), file=OutFile)
    print("NB-LDPC\tCodeLength: {}\tCodeRate: {}".format(CodeLength, CodeRate))
    for trial in range(TestLimit):
        print(trial)
        # print("Iteration\n", trial + 1, file=OutFile)
        print("Iteration\n", trial + 1)
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
        NoisySumInput = GaussNoise(BinaryInputWord, Var)
        NoisySumInput = NoisySumInput.reshape((1, NoisyBinaryInput.shape[1]))
        LLRV, NoisyInput = GenerateLLR(NoisySumInput, CodeLength, Field, InititalDelta, InfoLength, RowAdd)
        # print("Noisy Input\n", NoisyInput, file=OutFile)
        # print("Generate LLR\t", LLRV, file=OutFile)
        # print(InputWord)
        # print(NoisyInput)
        Pass, OutWord, it = Decode(NoisyInput, IterLim, LLRV, ASTable, MulTable, H, SigScale, Field, OutFile)
        OutWord = GFToInt(OutWord, Field, NoisySumInput, RowAdd)
        OutWord[:, InfoLength:] %= Field
        # print(Pass, file=OutFile)
        # print(Pass)
        # print("Final Output\n", OutWord, file=OutFile)
        OutWord = IntToBinary(OutWord, RowAdd, Field, InfoLength, CheckLength)
        SumInputWord = IntToBinary(SumInputWord, RowAdd, Field, InfoLength, CheckLength)
        FalseWord = len(np.where(OutWord != SumInputWord)[0])
        FalseWordNum += FalseWord
        # print("Loop: {}\t False: {}\t BER: {} Iteration: {}\n".format(trial + 1, FalseWordNum,
        #                                                               FalseWordNum / ((trial + 1) * len(OutWord)), it),
        #       file=OutFile)
        print("Loop: {}\t False: {}\t BER: {} Iteration: {}\n".format(trial + 1, FalseWordNum,
                                                                      FalseWordNum / ((trial + 1) * len(OutWord)), it))
        if FalseWord != 0:
            FalseCount += 1
        if FalseCount >= 10:
            break
    # OutFile.close()
    return


if __name__ == '__main__':
    main()
