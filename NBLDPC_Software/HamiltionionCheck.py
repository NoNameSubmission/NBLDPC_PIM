import numpy as np
from PEG_NEW import GenerateFromH, GFMatMul, DefaultTable, WhereToTuple


def CheckGirth(start, p, CheckNum, CheckMat):
    CheckConn = False
    for search in range(CheckNum):
        if search == start or search == (start + p) % CheckNum:
            continue
        if CheckMat[start][search] == 1 and CheckMat[search][[(start + p) % CheckNum]] == 1:
            CheckConn = True
            break
    return CheckConn


def DFS(previous, now, cycle, passed_node, conn, route):
    if now in route:
        i = 0
        for i in range(len(route)):
            if route[i] == now:
                break
        temp = route[i:].copy()
        temp.append(now)
        cycle.append(temp)
        # print(cycle)
        return
    if now in passed_node:
        return
    NodeNum, NodeNum = conn.shape
    for i in range(NodeNum):
        if i == previous or conn[now][i] == 0:
            continue
        passed_node.append(now)
        route.append(now)
        DFS(now, i, cycle, passed_node, conn, route)
        route.remove(now)
    return


def FRC(H, ASTable, MulTable):
    CheckNum, VariableNum = H.shape
    LowerMat = np.hstack((H, np.zeros((CheckNum, CheckNum), dtype=int)))
    UpperMat = np.hstack((np.zeros((VariableNum, VariableNum), dtype=int), H.transpose()))
    ConnMat = np.vstack((UpperMat, LowerMat))
    Pass = []
    CycleList = []
    Route = []
    DFS(-1, VariableNum, CycleList, Pass, ConnMat, Route)
    FRC_Fail = 10
    while FRC_Fail != 0:
        FRC_Fail = 0
        EdgeCount = np.zeros(ConnMat.shape)
        for Ring in CycleList:
            Product = [1, 1]
            RingLength = len(Ring)
            for i in range(len(Ring) - 1):
                Product[i % 2] = MulTable[ConnMat[Ring[i]][Ring[i + 1]]][Product[i % 2]]
                EdgeCount[Ring[i]][Ring[i + 1]] -= 1
                EdgeCount[Ring[i + 1]][Ring[i]] -= 1
            if Product[0] == Product[1]:
                FRC_Fail += 1
                for i in range(len(Ring) - 1):
                    EdgeCount[Ring[i]][Ring[i + 1]] += 2
                    EdgeCount[Ring[i + 1]][Ring[i]] += 2
        print(len(CycleList), FRC_Fail)
        # stop = input()
        # if int(stop) != 1:
        #     break
        MaxInfluence = EdgeCount.max()
        Edges = np.where(EdgeCount == MaxInfluence)
        Edges = WhereToTuple(Edges)
        np.random.shuffle(Edges)
        Row, Colum = Edges[0]
        ConnMat[Row][Colum] = ConnMat[Row][Colum] % 2 + 1
        ConnMat[Colum][Row] = ConnMat[Colum][Row] % 2 + 1
    return H


def main():
    CheckNum = 36
    VariableNum = 292  # C_{n}^{2}
    TotalEdge = 0
    CodeRate = (VariableNum - CheckNum) / VariableNum
    GF = 3
    H = np.zeros((CheckNum, VariableNum), dtype=int)
    ColumnDegree = 2
    CheckMat = np.zeros((CheckNum, CheckNum), dtype=int)
    CheckDegree = int(VariableNum * ColumnDegree / CheckNum)
    for i in range(CheckNum - 1):
        CheckMat[i][i + 1] += 1
        CheckMat[i + 1][i] += 1
        TotalEdge += 1
    CheckMat[CheckNum - 1][0] += 1
    CheckMat[0][CheckNum - 1] += 1
    TotalEdge += 1
    CheckConn = [0] * CheckNum
    for p in range(16, 2, -1):
        for i in range(CheckNum):
            skip = False
            if CheckMat[i][(i + p) % CheckNum] == 1:
                continue
            if CheckConn[i] >= CheckDegree or CheckConn[(i + p) % CheckNum] >= CheckDegree:
                continue
            skip = CheckGirth(i, p, CheckNum, CheckMat)
            if skip:
                continue
            CheckMat[i][(i + p) % CheckNum] += 1
            CheckMat[(i + p) % CheckNum][i] += 1
            CheckConn[i] += 1
            CheckConn[(i + p) % CheckNum] += 1
            TotalEdge += 1
        if TotalEdge >= VariableNum:
            break
    PossibleSpots = []
    for i in range(CheckNum):
        if CheckConn[i] < CheckDegree:
            PossibleSpots.append(i)
    RestEdge = VariableNum - TotalEdge
    for i in range(RestEdge):
        SelectList = []
        count = 0
        target = min(CheckConn)
        for item in PossibleSpots:
            if CheckConn[item] == target:
                SelectList.append(item)
                count += 1
        np.random.shuffle(SelectList)
        A = SelectList[0]
        SelectList = []
        for item in PossibleSpots:
            if CheckMat[A][item] == 0 and item != A:
                SelectList.append(item)
        np.random.shuffle(SelectList)
        B = SelectList[0]
        CheckMat[A][B] += 1
        CheckMat[B][A] += 1
        CheckConn[A] += 1
        CheckConn[B] += 1
        if CheckConn[A] >= CheckDegree:
            PossibleSpots.remove(A)
        if CheckConn[B] >= CheckDegree:
            PossibleSpots.remove(B)
        TotalEdge += 1
    # Limit = 0
    # for i in range(CheckNum):
    #     for j in range(i + 3, CheckNum, 3):
    #         if ExistingConn[i] >= CheckDegree:
    #             break
    #         if ExistingConn[j] >= CheckDegree:
    #             continue
    #         CheckMat[i][j] += 1
    #         CheckMat[j][i] += 1
    #         ExistingConn[i] += 1
    #         ExistingConn[j] += 1
    ExistingConn = [0] * VariableNum
    for i in range(CheckNum):
        for j in range(i + 1, CheckNum):
            if CheckMat[i][j] == 0:
                continue
            while True:
                MidVariable = np.random.randint(VariableNum)
                if ExistingConn[MidVariable] < ColumnDegree:
                    break
            H[i][MidVariable] = np.random.randint(1, GF)
            H[j][MidVariable] = np.random.randint(1, GF)
            ExistingConn[MidVariable] += 2
    # print(min(ExistingConn), max(ExistingConn))
    ASTable, MulTable, _ = DefaultTable(GF)
    H = FRC(H, ASTable, MulTable)
    # return
    G, OperationsH = GenerateFromH(H, ASTable, MulTable)
    H = GFMatMul(H, OperationsH, ASTable, MulTable)
    outfile = open("H_217_Hamilton.txt", 'w')
    for i in range(CheckNum):
        for j in range(VariableNum):
            print(int(H[i][j]), end=' ', file=outfile)
        print(file=outfile)
    outfile = open("G_217_Hamilton.txt", 'w')
    for i in range(VariableNum - CheckNum):
        for j in range(VariableNum):
            print(int(G[i][j]), end=' ', file=outfile)
        print(file=outfile)
    return


if __name__ == '__main__':
    main()
