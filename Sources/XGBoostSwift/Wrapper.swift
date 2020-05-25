import Cxgb

func LastError() -> String {
    let err = XGBGetLastError()
    let errMsg = String(cString: err!)
    return errMsg
}

// func PrintIfError(_ err: Int) {
//     if err >=0 {
//         let errMsg = LastError()
//         print("create xgdmatrix from file failed, err msg: \(errMsg)")
//         return nil
//     }
// }

func DMatrixFromFile(name fname: String, silent: Bool = true) -> DMatrixHandle? {
    var silence: Int32 = 0
    if silent {
        silence = 1
    }

    // var dm = DMatrix()
    var handle: DMatrixHandle?
    guard XGDMatrixCreateFromFile(fname, silence, &handle) >= 0 else {
        let errMsg = LastError()
        print("create xgdmatrix from file failed, err msg: \(errMsg)")
        return nil
    }
    return handle
}

func DMatrixFree(_ handle: DMatrixHandle) {
    guard XGDMatrixFree(handle) >= 0 else {
        let errMsg = LastError()
        print("free dmatrix failed, err msg: \(errMsg)")
        return
    }
}

func DMatrixNumRow(_ handle: DMatrixHandle) -> UInt64? {
    var nRow: UInt64 = 0
    guard XGDMatrixNumRow(handle, &nRow) >= 0 else {
        let errMsg = LastError()
        print("Get number of rows failed, err msg: \(errMsg)")
        return nil
    }
    return nRow
}

func DMatrixNumCol(_ handle: DMatrixHandle) -> UInt64? {
    var nCol: UInt64 = 0
    guard XGDMatrixNumCol(handle, &nCol) >= 0 else {
        let errMsg = LastError()
        print("Get number of cols failed, err msg: \(errMsg)")
        return nil
    }
    return nCol
}

func DMatrixGetFloatInfo(handle: DMatrixHandle, label: String) -> [Float]? {
    var result: UnsafePointer<Float>?
    var len: UInt64 = 0
    guard XGDMatrixGetFloatInfo(handle, label, &len, &result) >= 0 else {
        let errMsg = LastError()
        print("Get dmatrix float info failed, err msg: \(errMsg)")
        return nil
    }

    let buf = UnsafeBufferPointer(start: result, count: Int(len))
    return [Float](buf)
}

func BoosterCreate(dmHandles: inout [DMatrixHandle?]) -> BoosterHandle? {
    let lenDm: UInt64 = UInt64(dmHandles.count)
    var handle: BoosterHandle?
    guard XGBoosterCreate(&dmHandles, lenDm, &handle) >= 0 else {
        let errMsg = LastError()
        print("create booster failed, err msg: \(errMsg)")
        return nil
    }
    return handle
}

// func BoosterCreate(dmHandle: inout DMatrixHandle?, lenDm: UInt64) -> BoosterHandle? {
//     var handle: BoosterHandle?
//     guard XGBoosterCreate(&dmHandle, lenDm, &handle) >= 0 else {
//         let errMsg = LastError()
//         print("create booster failed, err msg: \(errMsg)")
//         return nil
//     }
//     return handle
// }

func BoosterFree(_ handle: BoosterHandle) {
    guard XGBoosterFree(handle) >= 0 else {
        let errMsg = LastError()
        print("free booster failed, err msg: \(errMsg)")
        return
    }
}

func BoosterSetParam(handle: BoosterHandle, key: String, value: String) {
    guard XGBoosterSetParam(handle, key, value) >= 0 else {
        let errMsg = LastError()
        print("create booster failed, err msg: \(errMsg)")
        return
    }
}

func BoosterUpdateOneIter(handle: BoosterHandle, nIter: Int, dmHandle: DMatrixHandle) {
    let iter: Int32 = Int32(nIter)
    guard XGBoosterUpdateOneIter(handle, iter, dmHandle) >= 0 else {
        let errMsg = LastError()
        print("create booster failed, err msg: \(errMsg)")
        return
    }
}

func BoosterEvalOneIter(handle: BoosterHandle, nIter: Int, dmHandle: inout [DMatrixHandle?],
                        evalNames: [String]) -> String {
    // TODO: solve dangling pointer
    var names: [UnsafePointer<Int8>?] = evalNames.map { UnsafePointer<Int8>($0) }
    // var dms:
    var result: UnsafePointer<Int8>?

    guard XGBoosterEvalOneIter(handle, Int32(nIter), &dmHandle, &names,
                               UInt64(evalNames.count), &result) >= 0 else {
        let errMsg = LastError()
        return "booster eval one iter failed, err msg: \(errMsg)"
    }

    return String(cString: result!)
}

func BoosterPredict(handle: BoosterHandle, dmHandle: DMatrixHandle,
                    optionMask: Int, nTreeLimit: UInt, training: Bool) -> [Float]? {
    let optioin: Int32 = Int32(optionMask)
    let treeLim: UInt32 = UInt32(nTreeLimit)
    var isTraining: Int32 = 0
    if training {
        isTraining = 1
    }

    var outLen: UInt64 = 0
    var result: UnsafePointer<Float>?
    // defer { result?.deallocate() }
    guard XGBoosterPredict(handle, dmHandle, optioin, treeLim, isTraining,
                           &outLen, &result) >= 0 else {
        let errMsg = LastError()
        print("create booster failed, err msg: \(errMsg)")
        return nil
    }
    // TODO: deal potential issue when outLen is bigger than Int
    let buf = UnsafeBufferPointer(start: result, count: Int(outLen))
    return [Float](buf)
}

func BoosterSaveJsonConfig(handle: BoosterHandle) -> String? {
    var len: UInt64 = 0
    var str: UnsafePointer<Int8>?
    guard XGBoosterSaveJsonConfig(handle, &len, &str) >= 0 else {
        let errMsg = LastError()
        print("save booster config as json string failed, err msg: \(errMsg)")
        return nil
    }
    let jsonStr = String(cString: str!)
    return jsonStr
}