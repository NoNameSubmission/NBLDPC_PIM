import numpy as np
from NBLDPC_TEST import ReadMatrix


def DFS(Start, Now, Mat, Pass):
    MinCycle = Mat.shape[1] + 1000
    for i in range(Mat.shape[1]):
        if Mat[Now][i] == 0:
            continue
        if i == Start and Pass[-1] != Start:
            return 1
        if i in Pass:
            continue
        Temp = Pass.copy()
        Temp.append(i)
        NowCycle = DFS(Start, i, Mat, Temp) + 1
        MinCycle = min(NowCycle, MinCycle)
    return MinCycle


def Girth(H):
    CheckLength, CodeLength = H.shape
    LowerMat = np.hstack((H, np.zeros((CheckLength, CheckLength))))
    UpperMat = np.hstack((np.zeros((CodeLength, CodeLength)), H.transpose()))
    ConnMat = np.vstack((UpperMat, LowerMat))
    DistMat = np.ones(ConnMat.shape) * CodeLength
    DistMat[np.where(ConnMat != 0)] /= CodeLength
    DistMat -= np.eye(CodeLength + CheckLength) * CodeLength
    MinCycle = CodeLength + CheckLength + 1000
    ConnMat[np.where(ConnMat == 0)] += CodeLength
    for i in range(CodeLength + CheckLength):
        for j in range(i):
            for k in range(j + 1, CodeLength + CheckLength):
                MinCycle = min(MinCycle, ConnMat[j, i] + ConnMat[i, k] + DistMat[j, k])
        for j in range(CodeLength + CheckLength):
            for k in range(CodeLength + CheckLength):
                DistMat[j, k] = min(DistMat[j, k], DistMat[j, i] + DistMat[i, k])
    # for i in range(CodeLength + CheckLength):
    #     MinCycle = min(DFS(i, i, ConnMat, [i]), MinCycle)
    print(MinCycle)
    return


def main():
    # InfoLength = 256
    # CodeRate = 8 / 9
    # CodeLength = int(InfoLength / CodeRate)
    # CheckLength = CodeLength - InfoLength
    CheckLength = 10
    CodeLength = 25
    H = ReadMatrix("H_217_Hamilton.txt", Shape=(CheckLength, CodeLength))
    Girth(H)
    return


if __name__ == '__main__':
    main()
