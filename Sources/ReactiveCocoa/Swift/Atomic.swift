//
//  Atomic.swift
//  ReactiveCocoa
//
//  Created by Justin Spahr-Summers on 2014-06-10.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

import Foundation

/// An atomic variable.
public final class Atomic<Value> {
	#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
	private var spinLock = OS_SPINLOCK_INIT
	#else
	private let nsLock = NSLock()
	#endif

	private var _value: Value
	
	/// Atomically gets or sets the value of the variable.
	public var value: Value {
		get {
			lock()
			let v = _value
			unlock()

			return v
		}
	
		set(newValue) {
			lock()
			_value = newValue
			unlock()
		}
	}
	
	/// Initializes the variable with the given initial value.
	public init(_ value: Value) {
		_value = value
	}
	
	private func lock() {
		#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
		OSSpinLockLock(&spinLock)
		#else
		nsLock.lock()
		#endif
	}
	
	private func unlock() {
		#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
		OSSpinLockUnlock(&spinLock)
		#else
		nsLock.unlock()
		#endif
	}
	
	/// Atomically replaces the contents of the variable.
	///
	/// Returns the old value.
	public func swap(newValue: Value) -> Value {
		return modify { _ in newValue }
	}

	/// Atomically modifies the variable.
	///
	/// Returns the old value.
	public func modify(@noescape action: Value -> Value) -> Value {
		lock()
		let oldValue = _value
		_value = action(_value)
		unlock()
		
		return oldValue
	}
	
	/// Atomically performs an arbitrary action using the current value of the
	/// variable.
	///
	/// Returns the result of the action.
	public func withValue<U>(@noescape action: Value -> U) -> U {
		lock()
		let result = action(_value)
		unlock()
		
		return result
	}
}
