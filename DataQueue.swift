//
//  DataQueue.swift
//
//  Created by helioz2000 on 21/1/2023.
//  For public consumption
//  Your milage may vary 

import Foundation

/**
 * DataQueue class implements a FIFO or ring buffer of type Data
 */
class DataQueue: NSObject {
    private var storage: Data
    private var storageSize: Int
    private var readPtr = Int(0)
    private var writePtr = Int(0)
    private var isFull = false
    
    // disabled, can't be called.
    @objc private override init() {
        storage = Data()
        storageSize = 0
        super.init()
    }
    
    init(_ size: Int) {
        storageSize = size
        storage = Data(count: storageSize)
    }
    
    @objc init(size: Int) {
        storageSize = size
        storage = Data(count: storageSize)
        super.init()
    }
    
    override var description: String {
        return "\(super.description)\nSize:\(storageSize), WritePtr:\(writePtr), ReadPtr:\(readPtr), isFull:\(isFull)\n\(self.storage)"
    }
    
    override var debugDescription: String {
        return "\(super.description)\nSize:\(storageSize), WritePtr:\(writePtr), ReadPtr:\(readPtr), isFull:\(isFull)\n\(self.hexDescription)"
    }
    
    var hexDescription: String {
        return storage.reduce("") {$0 + String(format: "%02X ", $1)}
    }
    
    /**
     * Write data to FIFO
     * - parameter data: byte sequence to add
     * - returns: number of bytes written
     * - Note: the maximum number of bytes written is restricted to the available size
     */
    @objc func writeData(data: Data) -> Int {
        var writeData: Data
        let availableBytes = writeAvailable()
        if availableBytes == 0 { return 0 }
        // restrict write to available write size
        if data.count > availableBytes {
            writeData = data.subdata(in: 0..<availableBytes)
        } else {
            writeData = data
        }
        var newWritePtr = writePtr + writeData.count
        if newWritePtr >= storageSize {
            // write would go past the end of storage
            // calculate where the data needs to be split
            let splitPtr = storageSize - writePtr
            newWritePtr = writeData.count - splitPtr
            // store at the end of storage
            storage.replaceSubrange(writePtr..<storageSize, with: writeData.subdata(in: 0..<splitPtr))
            // wrap storage to the start
            storage.replaceSubrange(0..<newWritePtr, with: writeData.subdata(in: splitPtr..<writeData.count))
        } else {
            // write will fit before end of storage
            storage.replaceSubrange(writePtr..<newWritePtr, with: writeData)
        }
        writePtr = newWritePtr
        if writePtr == readPtr { isFull = true }    // write pointer has wrapped and caught up with read pointer
        return writeData.count
    }
    
    /**
     * Read byte sequence from FIFO
     * - parameter numBytesToRead: number of bytes to read
     * - returns: byte sequence
     * - Note: The maximum number of bytes returned is the available number of bytes
     */
    @objc func readData(bytesToRead: Int) -> Data {
        var retData = Data()
        // limit reading to available qty
        let numBytes = min(bytesToRead, readAvailable())
        var newReadPtr = readPtr
        if (readPtr + numBytes) <= storageSize {
            newReadPtr = readPtr + numBytes
            retData = storage.subdata(in: readPtr..<newReadPtr)
        } else {
            retData = storage.subdata(in: readPtr..<storageSize)   // first lot to the end of storage
            newReadPtr = numBytes - retData.count
            retData += storage.subdata(in: 0..<newReadPtr)      // add seconds lot at the start of storage
        }
        readPtr = newReadPtr;
        isFull = false
        return retData
    }
    
    /**
     * Number of bytes available for reading
     * - returns: bytes available for reading
     */
    @objc func readAvailable() -> Int {
        let available = writePtr - readPtr;
        if available > 0 { return available }
        if available == 0 {
            if isFull { return storageSize }
            else { return 0 }
        }
        // write pointer has wrapped
        return storageSize - readPtr + writePtr
    }
    
    /**
     * Number of bytes available for writing
     * - returns: bytes available for writing
     */
    @objc func writeAvailable() -> Int {
        if readPtr == writePtr {
            if isFull {
                return 0
            } else {
                return storageSize
            }
        }
        let available = readPtr - writePtr;
        if available > 0 { return available }
        // write pointer has wrapped
        return storageSize - writePtr + readPtr
    }
    
    /**
     * Flush FIFO by resetting pointers to zero
     * The contents of the storage remains unchanged
     */
    @objc func flush() {
        readPtr = 0
        writePtr = 0
        isFull = false
    }
    
}
