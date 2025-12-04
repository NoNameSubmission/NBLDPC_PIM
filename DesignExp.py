from matplotlib import pyplot as plt
import matplotlib as mpl
import numpy as np
import pandas as pd
import os


mpl.rcParams['pdf.fonttype'] = 42
mpl.rcParams['ps.fonttype'] = 42
plt.rcParams['font.sans-serif'] = ['Arial']


def PlotSpace():
    CHIP_SPACE = 546.44 * 552.24
    ATOP = 306.192 * 473.61
    DTOP = CHIP_SPACE - ATOP
    CrossbarLimit = 8
    ANUM = [i for i in range(1, CrossbarLimit + 1)]
    AreaF = [ANUM[i] * ATOP + DTOP for i in range(CrossbarLimit)]
    RatioA = [1 - DTOP / (ANUM[i] * ATOP + DTOP) for i in range(CrossbarLimit)]
    LabelA = ['%.2f' % RatioA[i] for i in range(CrossbarLimit)]
    RatioB = [DTOP / (ANUM[i] * ATOP + DTOP) for i in range(CrossbarLimit)]
    LabelB = ['%.2f' % RatioB[i] for i in range(CrossbarLimit)]
    f = plt.bar(ANUM, RatioA, 0.5, label='Crossbar')
    plt.bar_label(f, LabelA, label_type='center')
    f = plt.bar(ANUM, RatioB, 0.5, label='Crossbar', bottom=RatioA)
    plt.bar_label(f, LabelB, label_type='center')
    # plt.savefig("/Users/xxxx/Desktop/Workplace/CHIP2024/ECC/DAC/Fig/Area.pdf", format='pdf')
    plt.show()
    return


def PlotDesignExp(InfoLength=256, CodeLength=288, IterationTimes=3, PropCycle=2, CalcBit=3, ADCTime=45, DigitalClock=76,
                  FixVN=True):
    """
    :param InfoLength: Total Length of Information Bits
    :param CodeLength: Total Length of the encoded Codeword
    :param IterationTimes: Total Times for NB-LDPC Iteration
    :param PropCycle: Cycles required for Forward-Backward Propagation
    :param CalcBit: Computing precision of the NB-LDPC decoder
    :param ADCTime: Time cost for 1 CIM computation or ADC sampling (ns)
    :param DigitalClock: Working Frequency of the chip (MHz)
    """
    CheckLength = CodeLength - InfoLength
    PIMCycle = np.ceil(ADCTime / (1000 / DigitalClock))
    CN_A = 8348.995122 * 1e-6 # um^2
    CN_P = 47.548 * 1e-3      # mW
    CN_L = 15.512 * 1e-3      # mW
    VN_A = 135.979 * 1e-6
    VN_P = 0.945 * 1e-3
    VN_L = 0.351 * 1e-3
    RE_A = 25.53 * 1e-6
    RE_P = 3.451 * 1e-3
    RE_L = 0.029418 * 1e-3
    TOP_A = 121116.820724 * 1e-6
    TOP_P = 1656 * 1e-3
    TOP_L = 212.252 * 1e-3
    Reg_L = 0.0050 * 1e-3
    Reg_P = 0.515 * 1e-3
    Reg_A = 0.8512 * 1e-6
    CONN_A = TOP_A - CN_A - CodeLength * VN_A - InfoLength * RE_A
    CONN_P = TOP_P - CN_P - CodeLength * VN_P - InfoLength * RE_P
    CONN_L = TOP_L - CN_L - CodeLength * VN_L - InfoLength * RE_L
    CN_NUM = np.array([1, 2, 4, 8, 16, 32])
    if FixVN:
        VN_NUM = 18
        CP_NUM = np.array([320, 160, 80, 40, 20, 10])
    else:
        VN_NUM = np.array([9, 18, 36, 72, 144, 288])
        CP_NUM = 160
    CPCycle = (InfoLength + CheckLength * 2) / CP_NUM * PIMCycle
    VNCycle = CodeLength / VN_NUM
    if FixVN:
        InitCycle = CPCycle.copy()
    else:
        InitCycle = VNCycle.copy()
    RegNum = np.zeros(len(CN_NUM))
    if FixVN:
        InitCycle[np.where(VNCycle > CPCycle)] = VNCycle
    else:
        InitCycle[np.where(VNCycle < CPCycle)] = CPCycle
    IterCycle = CheckLength / CN_NUM * PropCycle * IterationTimes
    VNEnergy = VN_NUM * VN_P * (VNCycle + IterationTimes) + VN_NUM / CodeLength * InfoLength * RE_P * IterationTimes
    CNEnergy = CN_NUM * CN_P * IterCycle
    CONNEnergy = CONN_P * IterCycle
    VNArea = VN_NUM * VN_A + VN_NUM / CodeLength * InfoLength * RE_A
    CNArea = CN_NUM * CN_A
    fig, ax = plt.subplots(layout='constrained')
    
    # Throughput
    width = 1 / len(CN_NUM)
    x = np.arange(len(CN_NUM)) * 1.1
    offset = width
    for i in range(len(CN_NUM)):
        BarValue = (InfoLength * 3 + CheckLength * 2) * DigitalClock / (IterCycle + InitCycle[i]) * 1e-3 # Unit Trans to Gbps
        if FixVN:
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM[i]) + ", VI=" + str(VN_NUM))
        else:
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM) + ", VI=" + str(VN_NUM[i]))
        ax.set_xticks(x + 0.5, CN_NUM)
    ax.grid(True, axis='y')
    plt.legend()
    plt.savefig("./Throughput.pdf", format='pdf')
    # plt.show()

    # Spare Time
    fig, ax = plt.subplots(layout='constrained')
    width = 1 / len(CN_NUM)
    x = np.arange(len(CN_NUM)) * 1.1
    offset = width
    for i in range(len(CN_NUM)):
        if FixVN:
            BarValue = abs(VNCycle - CPCycle[i])
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM[i]) + ", VI=" + str(VN_NUM))
        else:
            BarValue = abs(VNCycle[i] - CPCycle)
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM) + ", VI=" + str(VN_NUM[i]))
        ax.set_xticks(x + 0.5, CN_NUM)
    ax.grid(True, axis='y')
    plt.legend()
    plt.savefig("./SpareTime.pdf", format='pdf')
    # plt.show()

    # Power Efficiency
    fig, ax = plt.subplots(layout='constrained')
    width = 1 / len(CN_NUM)
    x = np.arange(len(CN_NUM)) * 1.1
    offset = width
    for i in range(len(CN_NUM)):
        CNLeak = InitCycle[i] * CN_L
        CNPower = (CNEnergy + CNLeak) / (IterCycle + InitCycle[i])
        CONNLeak = InitCycle[i] * CONN_L
        CONNPower = (CONNEnergy + CONNLeak) / (IterCycle + InitCycle[i])
        if FixVN:
            VNLeak = (IterCycle + InitCycle[i] - VNCycle - IterationTimes) * VN_L
            VNPower = (VNEnergy + VNLeak[i]) / (IterCycle + InitCycle[i])
            if VNCycle > CPCycle[i]:
                RegNum[i] = (VNCycle - CPCycle[i]) * VN_NUM * CalcBit
                RegEnergy = RegNum[i] * Reg_P
                RegLeak = Reg_L * RegNum[i] * (IterCycle + InitCycle[i] - 1)
                RegPower = (RegEnergy + RegLeak) / (IterCycle + InitCycle[i])
            else:
                RegPower = 0
        else:
            VNLeak = (IterCycle + InitCycle[i] - VNCycle[i] - IterationTimes) * VN_L
            VNPower = (VNEnergy[i] + VNLeak[i]) / (IterCycle + InitCycle[i])
            if VNCycle[i] > CPCycle:
                RegNum[i] = (VNCycle[i] - CPCycle) * VN_NUM[i] * CalcBit
                RegEnergy = RegNum[i] * Reg_P
                RegLeak = Reg_L * RegNum[i] * (IterCycle + InitCycle[i] - 1)
                RegPower = (RegEnergy + RegLeak) / (IterCycle + InitCycle[i])
            else:
                RegPower = 0
        BarValue = (InfoLength * 3 + CheckLength * 2) * DigitalClock / (CONNPower + VNPower + CNPower + RegPower) / (IterCycle + InitCycle[i]) * 1e-3 # Unit Trans to Tbps/W
        # print((np.array([CONN_P+VNPower[i]] * len(CN_NUM)) + CNPower), (IterCycle + InitCycle[i]))
        if FixVN:
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM[i]) + ", VI=" + str(VN_NUM))
        else:
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM) + ", VI=" + str(VN_NUM[i]))
        ax.set_xticks(x + 0.5, CN_NUM)
    ax.grid(True, axis='y')
    plt.legend()
    plt.savefig("./PowerEff.pdf", format='pdf')
    # plt.show()

    # Area Efficiency
    fig, ax = plt.subplots(layout='constrained')
    width = 1 / len(CN_NUM)
    x = np.arange(len(CN_NUM)) * 1.1
    offset = width
    for i in range(len(CN_NUM)):
        VNLeak = (IterCycle + InitCycle[i] - VNCycle - IterationTimes) * VN_L
        VNPower = (VNEnergy + VNLeak) / (IterCycle + InitCycle[i])
        CNLeak = InitCycle[i] * CN_L
        CNPower = (CNEnergy + CNLeak) / (IterCycle + InitCycle[i])
        CONNLeak = InitCycle[i] * CONN_L
        CONNPower = (CONNEnergy + CONNLeak) / (IterCycle + InitCycle[i])
        if FixVN:
            if VNCycle > CPCycle[i]:
                RegNum[i] = (VNCycle - CPCycle[i]) * VN_NUM * CalcBit
                RegEnergy = RegNum[i] * Reg_P
                RegLeak = Reg_L * RegNum[i] * (IterCycle + InitCycle[i] - 1)
                RegPower = (RegEnergy + RegLeak) / (IterCycle + InitCycle[i])
            else:
                RegPower = 0
            TotalArea = VNArea + CNArea + CONN_A + Reg_A * RegNum[i]
        else:
            if VNCycle[i] > CPCycle:
                RegNum[i] = (VNCycle[i] - CPCycle) * VN_NUM[i] * CalcBit
                RegEnergy = RegNum[i] * Reg_P
                RegLeak = Reg_L * RegNum[i] * (IterCycle + InitCycle[i] - 1)
                RegPower = (RegEnergy + RegLeak) / (IterCycle + InitCycle[i])
            else:
                RegPower = 0
            TotalArea = VNArea + CNArea + CONN_A + Reg_A * RegNum[i]
        BarValue = (InfoLength * 3 + CheckLength * 2) * DigitalClock / (IterCycle + InitCycle[i]) / TotalArea
        if FixVN:
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM[i]) + ", VI=" + str(VN_NUM))
        else:
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM) + ", VI=" + str(VN_NUM[i]))
    ax.set_xticks(x + 0.5, CN_NUM)
    plt.legend()
    plt.grid(True, axis='y')
    plt.savefig("./AreaEff.pdf", format='pdf')
    # plt.show()

    # FoM include Area Efficiency
    fig, ax = plt.subplots(layout='constrained')
    width = 1 / len(CN_NUM)
    x = np.arange(len(CN_NUM)) * 1.1
    offset = width
    for i in range(len(CN_NUM)):
        VNLeak = (IterCycle + InitCycle[i] - VNCycle - IterationTimes) * VN_L
        VNPower = (VNEnergy + VNLeak) / (IterCycle + InitCycle[i])
        CNLeak = InitCycle[i] * CN_L
        CNPower = (CNEnergy + CNLeak) / (IterCycle + InitCycle[i])
        CONNLeak = InitCycle[i] * CONN_L
        CONNPower = (CONNEnergy + CONNLeak) / (IterCycle + InitCycle[i])
        if FixVN:
            if VNCycle > CPCycle[i]:
                RegNum[i] = (VNCycle - CPCycle[i]) * VN_NUM * CalcBit
                RegEnergy = RegNum[i] * Reg_P
                RegLeak = Reg_L * RegNum[i] * (IterCycle + InitCycle[i] - 1)
                RegPower = (RegEnergy + RegLeak) / (IterCycle + InitCycle[i])
            else:
                RegPower = 0
        else:
            if VNCycle[i] > CPCycle:
                RegNum[i] = (VNCycle[i] - CPCycle) * VN_NUM[i] * CalcBit
                RegEnergy = RegNum[i] * Reg_P
                RegLeak = Reg_L * RegNum[i] * (IterCycle + InitCycle[i] - 1)
                RegPower = (RegEnergy + RegLeak) / (IterCycle + InitCycle[i])
            else:
                RegPower = 0
        TotalArea = VNArea + CNArea + CONN_A + Reg_A * RegNum[i]
        BarValue = (InfoLength * 3 + CheckLength * 2) * DigitalClock / (CONNPower + VNPower + CNPower + RegPower) / (IterCycle + InitCycle[i]) / TotalArea
        if FixVN:
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM[i]) + ", VI=" + str(VN_NUM))
        else:
            ax.bar(x + offset * i, BarValue, width=width, label="CPNP=" + str(CP_NUM) + ", VI=" + str(VN_NUM[i]))
    ax.set_xticks(x + 0.5, CN_NUM)
    plt.legend()
    plt.grid(True, axis='y')
    plt.savefig("./FoM.pdf", format='pdf')
    # plt.show()
    return


def main():
    # PlotSpace()
    PlotDesignExp(FixVN=False)
    return


if __name__ == '__main__':
    main()
