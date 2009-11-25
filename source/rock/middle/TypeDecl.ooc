import structs/HashMap
import ../frontend/Token
import Expression, Line, Type, Visitor, Declaration, VariableDecl,
    FunctionDecl, FunctionCall, Module, VariableAccess
import tinker/[Resolver, Response, Trail]

TypeDecl: abstract class extends Declaration {

    name: String
    externName: String = null

    variables := HashMap<VariableDecl> new()
    functions := HashMap<FunctionDecl> new()

    thisDecl : VariableDecl

    type: Type
    superType: Type
    
    module: Module = null
    
    init: func ~typeDecl (=name, =superType, .token) {
        super(token)
        type = BaseType new(name, token)
        type as BaseType ref = this
        thisDecl = VariableDecl new(type, "this", nullToken)
    }
    
    addVariable: func (vDecl: VariableDecl) {
        //printf("______ %s %s just got variable %s\n", class name, vDecl toString())
        variables put(vDecl name, vDecl)
        vDecl owner = this
    }
    
    addFunction: func (fDecl: FunctionDecl) {
        //printf("______ %s %s just got function %s\n", class name, name, fDecl toString())
        functions put(fDecl name, fDecl)
        fDecl owner = this
    }
    
    getFunction: func (fName, fSuffix: String) -> FunctionDecl {
        // TODO add suffix handling
        functions get(fName)
    }
    
    getVariable: func (vName: String) -> VariableDecl {
        variables get(vName)
    }
    
    underName: func -> String {
        
        // TODO underize it.
        /*
        if(module != null) {
            printf("module fullName = %s\n", module fullName)
            printf("module packageName = %s\n", module packageName)
            printf("externName = %s\n", externName)
            printf("module packageName isEmpty() = %d\n", module packageName isEmpty())
            printf("isExtern = %d\n", isExtern())
        }
        */
        if(module != null && !module packageName isEmpty() && !isExtern()) {
			return module packageName + "__" + name
        }
            
		return name       
    }
    
    getExternName: func -> String {
        return (externName && !externName isEmpty()) ? externName : name
    }
    
    isExtern: func -> Bool { externName != null }
    
    superRef: func -> TypeDecl {
        superType ? superType getRef() : null
    }
    
    getFunction: func ~call (call: FunctionCall) -> FunctionDecl {
        return getFunction(call name, call suffix, call)
    }
    
    getFunction: func ~nameSuffCall (name, suffix: String, call: FunctionCall) -> FunctionDecl {
        return getFunction(name, suffix, call, true);
    }
    
    getFunction: func ~nameSuffCallRec (name, suffix: String, call: FunctionCall, recursive: Bool) -> FunctionDecl {
        return getFunction(name, suffix, call, recursive, 0, null)
    }
    
    getFunction: func ~real (name, suffix: String, call: FunctionCall,
        recursive: Bool, bestScore: Int, bestMatch: FunctionDecl) -> FunctionDecl {
            
        for(fDecl: FunctionDecl in functions) {
            if(fDecl name equals(name) && (suffix == null || fDecl suffix equals(suffix))) {
                if(!call) return fDecl
                score := call getScore(fDecl)
                if(score == -1) return null
                if(score > bestScore) {
                    bestScore = score
                    bestMatch = fDecl
                }
            }
        }
        
        if(recursive && superRef()) {
            return superRef() getFunction(name, suffix, call, true, bestScore, bestMatch)
        }
        return bestMatch
        
    }
    
    getType: func -> Type { type }

    isResolved: func -> Bool { false }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        
        trail push(this)
        
        //printf("======\nResolving type decl %s\n", toString())
        
        for(vDecl in variables) {
            response := vDecl resolve(trail, res)
            //printf("Response of vDecl %s = %s\n", vDecl toString(), response toString())
            if(!response ok()) return response
        }
        
        for(fDecl in functions) {
            response := fDecl resolve(trail, res)
            //printf("Response of fDecl %s = %s\n", fDecl toString(), response toString())
            if(!response ok()) return response
        }
        
        trail pop(this)
        
        return Responses OK
        
    }
    
    resolveAccess: func (access: VariableAccess) {
        printf("? Looking for variable %s in %s\n", access name, name)
        vDecl : VariableDecl = null
        vDecl = variables get(access name)
        if(vDecl) {
            "&&&&&&&& Found vDecl for %s\n" format(access name) println()
            if(access suggest(vDecl) && access expr == null) {
                varAcc := VariableAccess new("this", nullToken)
                varAcc suggest(thisDecl)
                access expr = varAcc
            }
        }
    }
    
    resolveCall: func (call : FunctionCall) {
        printf("? Looking for function %s in %s\n", call name, name)
        fDecl : FunctionDecl = null
        fDecl = functions get(call name)
        if(fDecl) {
            "&&&&&&&& Found fDecl for %s\n" format(call name) println()
            call suggest(fDecl)
        }
    }
    
    toString: func -> String {
        class name + ' ' + name
    }
    
    

}

BuiltinType: class extends TypeDecl {
    
    init: func ~builtinType (.name, .token) {
        super(name, null, token)
    }
    
    underName: func -> String { name }
    
    accept: func (v: Visitor) { /* yeah, right. */ }
    
}

