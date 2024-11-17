import numpy as np


def EliminateRow(RowNum, Matrix, TargetPlace, StandPlace, ASTable, MulTable):
    for k in range(RowNum):
        if k == StandPlace or Matrix[k][TargetPlace] == 0:
            continue
        InvElement = np.where(ASTable[Matrix[k][TargetPlace]] == 0)
        Matrix[k] = ASTable[Matrix[k], MulTable[InvElement, Matrix[StandPlace]]]
    return Matrix


def RowHandlingProcess(i, j, Matrix, ASTable, MulTable, RowNum, InfoNum):
    RowInv = np.where(MulTable[Matrix[j][i + InfoNum]] == 1)
    Matrix[j] = MulTable[RowInv[0], Matrix[j]]
    # Second Zerolize other row in the column
    Matrix = EliminateRow(RowNum, Matrix, i + InfoNum, j, ASTable, MulTable)
    # Third Standardize the Matrix
    TempVec = Matrix[i].copy()
    Matrix[i] = Matrix[j].copy()
    Matrix[j] = TempVec.copy()
    return Matrix


def GaussianElimination(Matrix, ASTable, MulTable):
    """
    :param Matrix: np.array [RowNum, ColNum]
    :param ASTable: np.array [Max Value, Max Value]
    :param MulTable: np.array [Max Value, Max Value]
    :return: Operations: np.array [RowNum, RowNum]
    :return: Matrix: np.array [RowNum, ColNum]
    """
    RowNum, ColNum = Matrix.shape
    InfoNum = ColNum - RowNum
    MaxValue, _ = ASTable.shape
    OperationsCol = np.eye(ColNum, dtype=int)
    OperationsG = np.eye(ColNum, dtype=int)
    BanList = []
    for i in range(MulTable.shape[0]):
        if 1 not in MulTable[i]:
            BanList.append(i)
    Count = 0
    j = 0
    for i in range(min(RowNum, ColNum)):
        OldCount = Count
        while j < RowNum:
            if j >= i and Matrix[j][i + InfoNum] not in BanList:
                Matrix = RowHandlingProcess(i, j, Matrix, ASTable, MulTable, RowNum, InfoNum)
                break
            if j == RowNum - 1:
                j = i
                Matrix[:, [Count, i + InfoNum]] = Matrix[:, [i + InfoNum, Count]]
                OperationsCol[:, [Count, i + InfoNum]] = OperationsCol[:, [i + InfoNum, Count]]
                Count += 1
                if Count == OldCount:
                    Index = np.where(Matrix[:, i + InfoNum] != 0)[0]
                    for that in Index:
                        ASInv = np.where(ASTable[Matrix[that, i + InfoNum]] == 0)[0]
                        OperationsG[that + InfoNum, i + InfoNum] = ASTable[OperationsG[that, i + InfoNum], ASInv]
                    break
                if Count >= InfoNum:
                    Count = 0
                continue
            j += 1
    return Matrix, OperationsCol, OperationsG


def GenerateFromH(H_Matrix, ASTable, MulTable):
    """
    :param H_Matrix:    np.array [CheckNum, TotalNum] Check Matrix
    :param ASTable: np.array [Max Value, Max Value]
    :param MulTable: np.array [Max Value, Max Value]
    :return: G_Matrix:  np.array [InfoNum, TotalNum] Generator Matrix
    :return: Operations: np.array [CheckNum, CheckNum]
    """
    CheckNum, TotalNum = H_Matrix.shape
    InfoNum = TotalNum - CheckNum
    I_Generate = np.diag([1 for _ in range(InfoNum)])
    X_Generate = np.zeros((InfoNum, CheckNum), dtype=int)
    NewH, Operations, OperationsG = GaussianElimination(H_Matrix.copy(), ASTable, MulTable)
    for i in range(InfoNum):
        for j in range(CheckNum):
            if NewH[j, j + InfoNum] == 1:
                X_Generate[i][j] = np.where(ASTable[NewH[:, :InfoNum].transpose()[i][j]] == 0)[0][0]
            else:
                X_Generate[i][j] = np.random.randint(0, ASTable.shape[0], dtype=np.int)
    G = np.append(I_Generate, X_Generate, axis=1)
    G = GFMatMul(G, OperationsG.transpose(), ASTable, MulTable)
    return G, Operations


def DFS(Start, End, Conn, NodeNum, RunList):
    if Start == End:
        return 1
    Routes = 0
    for i in range(NodeNum):
        if RunList[i] == 1:
            return 1
        if Conn[Start][i] == 1:
            RunList[i] += 1
            Routes += DFS(i, End, Conn, NodeNum, RunList)
    return Routes


def UpdateDist(DistMat, NewEdge):
    NodeNum, _ = DistMat.shape
    for i in range(NodeNum):
        for j in range(i, NodeNum):
            DistMat[i][j] = min(DistMat[i][j], DistMat[i][NewEdge] + DistMat[NewEdge][j])
            DistMat[j][i] = DistMat[i][j]
    return DistMat


def AddEdge(Check, Variable, ConnMat, DistMat, DistH, ColNum):
    ConnMat[Variable][Check + ColNum] = 1
    ConnMat[Check + ColNum][Variable] = 1
    DistMat[Variable][Check + ColNum] = 1
    DistMat[Check + ColNum][Variable] = 1
    DistMat = UpdateDist(DistMat, Check + ColNum)
    DistMat = UpdateDist(DistMat, Variable)
    DistH = DistMat[ColNum:, ColNum:] / 2
    DistH[np.where(DistH == 300)] = 600
    return ConnMat, DistMat, DistH


def RandPEG(ColNum, RowNum, CheckDegree, VariDegree, Lmax):
    H_init = np.zeros((RowNum, ColNum), dtype=np.int)
    ConnMat = np.zeros((RowNum + ColNum, RowNum + ColNum), dtype=np.int)
    ColCount = np.zeros(ColNum, dtype=np.int)
    RowCount = np.zeros(RowNum, dtype=np.int)
    DistH = np.ones((RowNum, RowNum), dtype=np.int) * 600
    DistMat = np.ones((RowNum + ColNum, RowNum + ColNum), dtype=np.int) * 600
    for i in range(ColNum + RowNum):
        if i < RowNum:
            DistH[i][i] = 0
        DistMat[i][i] = 0
    for i in range(RowNum):
        Target = max(i - 1, 0)
        ConnMat, DistMat, DistH = AddEdge(i, Target, ConnMat, DistMat, DistH, ColNum)
        H_init[i][Target] = 1
        ColCount[Target] += 1
        RowCount[i] += 1
    EndRow = 0
    for j in range(1, ColNum):
        H_init[EndRow][j] += 1
        ConnMat, DistMat, DistH = AddEdge(EndRow, j, ConnMat, DistMat, DistH, ColNum)
        RowCount[EndRow] += 1
        ColCount[j] += 1
        if RowCount[EndRow] >= CheckDegree:
            EndRow += 1
    for i in range(EndRow, RowNum):
        print(i)
        print(len(set(np.where(H_init != 0)[1])))
        for k in range(CheckDegree - RowCount[i]):
            # if Lmax in DistH[i, :]:
            #     UpperBound = min(Lmax, DistH[i, :].max())
            # else:
            UpperBound = DistH[i, :].max()
            while True:
                Index = np.where(DistH[i, :] == UpperBound)[0]
                ColIndex = np.where(H_init[Index, :] != 0)[1]
                ColIndex = list(set(ColIndex))
                # PossibleVariList = []
                # for j in Index:
                #     TempList = np.where(H_init[j, :] != 0)[0]
                #     for item in TempList:
                #         PossibleVariList.append(item)
                # if not PossibleVariList:
                #     PossibleVariList = np.where(H_init[i, :] == 0)[0]
                # PossibleVariList = set(PossibleVariList)
                # PossibleVariList = list(PossibleVariList)
                ColMin = ColCount[ColIndex].min()
                RemoveList = []
                for item in ColIndex:
                    if ColCount[item] != ColMin or ColCount[item] == VariDegree or H_init[i, item] == 1:
                        RemoveList.append(item)
                for that in RemoveList:
                    ColIndex.remove(that)
                if not ColIndex:
                    UpperBound -= 1
                    continue
                CycleList = []
                for item in ColIndex:
                    CycleList.append(DFS(i + ColNum, item, ConnMat, RowNum + ColNum, np.zeros(RowNum + ColNum)))
                CycleMin = min(CycleList)
                RemoveList = []
                for item in range(len(CycleList)):
                    if CycleList[item] != CycleMin:
                        RemoveList.append(ColIndex[item])
                for that in RemoveList:
                    ColIndex.remove(that)
                if not ColIndex:
                    UpperBound -= 1
                    continue
                break
            np.random.shuffle(ColIndex)
            ConnMat, DistMat, DistH = AddEdge(i, ColIndex[0], ConnMat, DistMat, DistH, ColNum)
            H_init[i][ColIndex[0]] = 1
            ColCount[ColIndex[0]] += 1
            RowCount[i] += 1
            if RowCount[i] >= CheckDegree:
                break
    return H_init


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


def GFMatMul(M1, M2, ASTable, MulTable):
    Left, Middle = M1.shape
    Middle, Right = M2.shape
    Output = np.zeros((Left, Right), dtype=int)
    for i in range(Left):
        print(i)
        for j in range(Right):
            for k in range(Middle):
                Temp = MulTable[M1[i][k]][M2[k][j]]
                Output[i][j] = ASTable[Temp][Output[i][j]]
    return Output


def main():
    InfoLength = 256
    CodeRate = 8 / 9
    CodeLength = int(InfoLength / CodeRate)
    CheckLength = CodeLength - InfoLength
    VariDegree = 2
    CheckDegree = int(CodeLength * VariDegree / CheckLength)
    Field = 3
    InFileH = open("H_256_8_9_Improved.txt", 'r')
    OutFileH = open("H_256_8_9_try.txt", 'w')
    OutFileG = open("G_256_8_9_try.txt", 'w')
    GF = 600
    # H_init = RandPEG(CodeLength, CheckLength, CheckDegree, VariDegree, GF)
    ReadFile = InFileH.read()
    ReadFile = ReadFile.split('\n')
    H_init = np.zeros((CheckLength, CodeLength), dtype=int)
    for i in range(CheckLength):
        TEMP_STR = ReadFile[i].split(' ')
        for j in range(CodeLength):
            H_init[i][j] = int(TEMP_STR[j])
    for i in range(CheckLength):
        temp = np.random.randint(1, 3)
        for j in range(CheckLength):
            if H_init[i][j] != 0:
                H_init[i][j] = temp
    # for i in range(CheckLength):
    #     Index = np.where(H_init[i] == 1)
    #     Content = (np.array([j % (Field - 1) for j in range(len(Index[0]))], dtype=np.int) + i) % (Field - 1) + 1
    #     np.random.shuffle(Content)
    #     H_init[i][Index] = Content
    ASTable, MulTable, _ = DefaultTable(Field)
    G, OperationsH = GenerateFromH(H_init, ASTable, MulTable)
    H = GFMatMul(H_init, OperationsH, ASTable, MulTable)
    CheckResult = GFMatMul(G, H.transpose(), ASTable, MulTable)
    print(np.where(CheckResult != 0))
    for i in range(CheckLength):
        for j in range(CodeLength):
            print(H[i][j], end=' ', file=OutFileH)
        print(file=OutFileH)
    for i in range(InfoLength):
        for j in range(CodeLength):
            print(G[i][j], end=' ', file=OutFileG)
        print(file=OutFileG)
    ColCount = np.zeros(CodeLength, dtype=int)
    RowCount = np.zeros(CheckLength, dtype=int)
    for i in range(CheckLength):
        for j in range(CheckLength + InfoLength):
            if H_init[i][j] != 0:
                ColCount[j] += 1
                RowCount[i] += 1
    print(np.where(ColCount != VariDegree), np.where(RowCount != CheckDegree))


if __name__ == '__main__':
    main()
