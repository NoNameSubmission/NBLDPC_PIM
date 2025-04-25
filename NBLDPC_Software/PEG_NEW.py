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
                X_Generate[i][j] = np.random.randint(0, ASTable.shape[0], dtype=int)
    G = np.append(I_Generate, X_Generate, axis=1)
    G = GFMatMul(G, OperationsG.transpose(), ASTable, MulTable)
    return G, Operations


def WhereToTuple(WhereList):
    Temp1 = WhereList[0]
    Temp2 = WhereList[1]
    OutList = [(Temp1[i], Temp2[i]) for i in range(len(Temp2))]
    return OutList


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


def AddEdge(Check, Variable, ConnMat, DistMat, ColNum):
    ConnMat[Variable][Check + ColNum] = 1
    ConnMat[Check + ColNum][Variable] = 1
    DistMat[Variable][Check + ColNum] = 1
    DistMat[Check + ColNum][Variable] = 1
    DistMat = UpdateDist(DistMat, Check + ColNum)
    DistMat = UpdateDist(DistMat, Variable)
    return ConnMat, DistMat


def RandPEG(ColNum, RowNum, CheckDegree, VariDegree, Lmax):
    H_init = np.zeros((RowNum, ColNum), dtype=int)
    ConnMat = np.eye(RowNum + ColNum, dtype=int)
    ColCount = np.zeros(ColNum, dtype=int)
    RowCount = np.zeros(RowNum, dtype=int)
    DistMat = np.ones((RowNum + ColNum, RowNum + ColNum), dtype=int) * 600
    for i in range(RowNum + ColNum):
        DistMat[i, i] = 0
    TotalEdge = RowNum * CheckDegree
    Edges = 0
    while Edges < TotalEdge:
        print(Edges)
        if Edges % 2 == 0:
            PossibleIndex = np.where(RowCount < CheckDegree)[0] + ColNum
            UpperBound = np.max(DistMat[PossibleIndex, :ColNum])
        else:
            PossibleIndex = np.where(ColCount < VariDegree)[0]
            UpperBound = np.max(DistMat[ColNum:, PossibleIndex])
        while True:
            PossibleSpots = np.where(DistMat[ColNum:, :ColNum] == UpperBound)
            if len(PossibleSpots[0]) == 0:
                UpperBound -= 1
                continue
            PossibleSpots = WhereToTuple(PossibleSpots)
            RemoveList = []
            for item in PossibleSpots:
                if H_init[item] == 1 or ColCount[item[1]] >= VariDegree or RowCount[item[0]] >= CheckDegree:
                    RemoveList.append(item)
            for item in RemoveList:
                PossibleSpots.remove(item)
            if not PossibleSpots:
                UpperBound -= 1
                continue
            CycleList = []
            for item in PossibleSpots:
                CycleList.append(DFS(item[0] + ColNum, item[1], ConnMat,
                                     RowNum + ColNum, np.zeros(RowNum + ColNum)))
            CycleMin = min(CycleList)
            RemoveList = []
            for item in range(len(CycleList)):
                if CycleList[item] != CycleMin:
                    RemoveList.append(PossibleSpots[item])
            for that in RemoveList:
                PossibleSpots.remove(that)
            if not PossibleSpots:
                UpperBound -= 1
                continue
            break
        np.random.shuffle(PossibleSpots)
        ConnMat, DistMat = AddEdge(PossibleSpots[0][0], PossibleSpots[0][1], ConnMat, DistMat, ColNum)
        H_init[PossibleSpots[0][0]][PossibleSpots[0][1]] = 1
        ColCount[PossibleSpots[0][1]] += 1
        RowCount[PossibleSpots[0][0]] += 1
        Edges += 1
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
    OutFileH = open("H_1024_8_9_new.txt", 'w')
    OutFileG = open("G_1024_8_9_new.txt", 'w')
    GF = 600
    H_init = RandPEG(CodeLength, CheckLength, CheckDegree, VariDegree, GF)
    for i in range(CheckLength):
        Index = np.where(H_init[i] == 1)
        Content = (np.array([j % (Field - 1) for j in range(len(Index[0]))], dtype=int) + i) % (Field - 1) + 1
        np.random.shuffle(Content)
        H_init[i][Index] = Content
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
