function _OCProxy(object) {
    var invoke = function(...args) {
        // console.log("invoke" + invoke.__OCFuncName)

        if (!invoke.__OCFuncName) {
            return;
        }
        var cArgs = args
        for (let i in cArgs) {
            if (cArgs[i].__OCObject) {
                cArgs[i] = cArgs[i].__OCObject;
            }
        }
        const instance = _OC_Invoke(invoke.__OCObject, invoke.__OCFuncName, ...cArgs);
        if (instance) {
            return instance;
        }
    };
    invoke.__OCObject = object;
    
    return new Proxy(invoke, {
        get(target, property) {
            if (property == 'valueOf' || property == 'toString' || typeof(property) != 'string' || property.startsWith('__OC')) {
                return target[property];
            }
            // console.log("get:" + target.__OCObject + property)

            const object = _OC_Getter(target.__OCObject, property);
            var proxy = object ?? _OCProxy(target.__OCObject);
            proxy.__OCFuncName = property;
            return proxy;
        },
        set(target, property, value) {
            if (property == 'valueOf' || property == 'toString' || typeof(property) != 'string' || property.startsWith('__OC')) {
                target[property] = value;
                return true;
            }
            // console.log("set:" + target.__OCObject + property)

            var nValue = value
            if (nValue.__OCObject) {
                nValue = nValue.__OCObject;
            }
            _OC_Setter(target.__OCObject, property, nValue);
            return true;
        }
    });
}

function AspectAfter(clz, sel, func) {
    _OC_AspectAfter(clz, sel, func.toString());
}

function AspectBefore(clz, sel, func) {
    _OC_AspectBefore(clz, sel, func.toString());
}

function AspectReplace(clz, sel, func) {
    _OC_AspectReplace(clz, sel, func.toString());
}

function Class(name) {
    return _OC_Class(name);
}

// NSValue

function CGRect(...args) {
    return _OC_NSValue("CGRect", ...args)
}

function CGVector(...args) {
    return _OC_NSValue("CGVector", ...args)
}

function CGSize(...args) {
    return _OC_NSValue("CGSize", ...args)
}

function CGPoint(...args) {
    return _OC_NSValue("CGPoint", ...args)
}

function CGAffineTransform(...args) {
    return _OC_NSValue("CGAffineTransform", ...args)
}

function UIEdgeInsets(...args) {
    return _OC_NSValue("UIEdgeInsets", ...args)
}

function NSDirectionalEdgeInsets(...args) {
    return _OC_NSValue("NSDirectionalEdgeInsets", ...args)
}

function UIOffset(...args) {
    return _OC_NSValue("UIOffset", ...args)
}

function NSRange(...args) {
    return _OC_NSValue("NSRange", ...args)
}

// NSNumber

function Int(...args) {
    return _OC_NSNumber("NSInteger", ...args)
}

function UInt(...args) {
    return _OC_NSNumber("NSUInteger", ...args)
}

function BOOL(...args) {
    return _OC_NSNumber("BOOL", ...args)
}

function String(arg) {
    return _OC_NSString(arg)
}
