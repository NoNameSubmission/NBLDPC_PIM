import numpy as np
from PEG_NEW import GenerateFromH, GFMatMul, DefaultTable

def main():
    RequiredGirth = 3  # >= 3
    Field = 3
    CheckNum = 40
    ConnMat = np.identity(CheckNum)
    DistMat = np.ones((CheckNum, CheckNum)) * CheckNum
    for i in range(CheckNum):
        ConnMat[i, (i + 1) % CheckNum] += 1
        ConnMat[(i + 1) % CheckNum, i] += 1
        DistMat[i, (i + 1) % CheckNum] = 1
        DistMat[(i + 1) % CheckNum, i] = 1
        DistMat[i, i] = 0
    for k in range(CheckNum):
        for i in range(CheckNum):
            for j in range(CheckNum):
                DistMat[i, j] = min(DistMat[i, j], DistMat[i, k] + DistMat[k, j])
    PossibleList = np.arange(CheckNum)
    VariableNum = CheckNum
    while len(PossibleList) != 0:
        np.random.shuffle(PossibleList)
        StartPoint = PossibleList[0]
        PossibleTarget = np.where(DistMat[StartPoint] == RequiredGirth - 1)[0]
        if len(PossibleTarget) == 0:
            PossibleList = PossibleList[1:]
            continue
        np.random.shuffle(PossibleTarget)
        # print(PossibleTarget)
        EndPoint = PossibleTarget[0]
        ConnMat[StartPoint, EndPoint] += 1
        ConnMat[EndPoint, StartPoint] += 1
        DistMat[StartPoint, EndPoint] = 1
        DistMat[EndPoint, StartPoint] = 1
        VariableNum += 1
        for i in range(CheckNum):
            for j in range(CheckNum):
                DistMat[i, j] = min(DistMat[i, j], DistMat[i, StartPoint] + DistMat[StartPoint, j])
                DistMat[i, j] = min(DistMat[i, j], DistMat[i, EndPoint] + DistMat[EndPoint, j])
    print(VariableNum, 1 - CheckNum * 2 / (VariableNum + CheckNum))
    # H = np.zeros((CheckNum, VariableNum), dtype=int)
    # PossibleList = np.arange(VariableNum)
    # for i in range(CheckNum):
    #     for j in range(i + 1, CheckNum):
    #         if ConnMat[i, j] == 0:
    #             continue
    #         np.random.shuffle(PossibleList)
    #         SelctV = PossibleList[0]
    #         H[i, SelctV] = np.random.randint(1, Field)
    #         H[j, SelctV] = np.random.randint(1, Field)
    #         PossibleList = PossibleList[1:]
    # ASTable, MulTable, _ = DefaultTable(Field)
    # G, OperationsH = GenerateFromH(H, ASTable, MulTable)
    # H = GFMatMul(H, OperationsH, ASTable, MulTable)
    # outfile = open("H_217_Hamilton.txt", 'w')
    # for i in range(CheckNum):
    #     for j in range(VariableNum):
    #         print(int(H[i][j]), end=' ', file=outfile)
    #     print(file=outfile)
    # outfile = open("G_217_Hamilton.txt", 'w')
    # for i in range(VariableNum - CheckNum):
    #     for j in range(VariableNum):
    #         print(int(G[i][j]), end=' ', file=outfile)
    #     print(file=outfile)
    return


if __name__ == '__main__':
    main()
