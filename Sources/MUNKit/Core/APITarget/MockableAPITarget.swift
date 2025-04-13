//
//  MockableAPITarget.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public protocol MUNMockableAPITarget: MUNAPITarget {
    var isMockEnabled: Bool { get }
    
    func getMockFileName() -> String?
}

extension MUNMockableAPITarget {
    var sampleData: Data { getSampleData() }

    private func getSampleData() -> Data {
        guard let mockFileName = getMockFileName() else {
            print("🕸️💽🆓 The request \(path) does not use mock data.")
            return Data()
        }

        return getSampleDataFromFileWithName(mockFileName)
    }
}

public protocol MockablePaginationMobileApiTarget: MUNMockableAPITarget {
    var pageIndexParameterName: String { get }
    var pageSizeParameterName: String { get }
}

extension MockablePaginationMobileApiTarget {
    var sampleData: Data { getSampleData() }

    private func getSampleData() -> Data {
        guard var mockFileName = getMockFileName() else {
            print("🕸️💽🆓 The request \(path) does not use mock data.")
            return Data()
        }

        if
            let pageIndex = parameters[pageIndexParameterName],
            let pageSize = parameters[pageSizeParameterName]
        {
            mockFileName = "\(mockFileName)&PI=\(pageIndex)&PS=\(pageSize)"
        }

        return getSampleDataFromFileWithName(mockFileName)
    }
}

extension MUNMockableAPITarget {
    func getSampleDataFromFileWithName(_ mockFileName: String) -> Data {
        let logStart = "For the request \(path), mock data"
        let mockExtension = "json"

        guard let mockFileUrl = Bundle.main.url(forResource: mockFileName, withExtension: mockExtension) else {
            print("🕸️💽🚨 \(logStart) \(mockFileName).\(mockExtension) not found.")
            return Data()
        }

        do {
            let data = try Data(contentsOf: mockFileUrl)
            print("🕸️💽✅ \(logStart) successfully read from URL: \(mockFileUrl).")
            return data
        } catch {
            print("🕸️💽🚨\n\(logStart) from file \(mockFileName).\(mockExtension) could not be read.\nError: \(error)")
            return Data()
        }
    }
}
