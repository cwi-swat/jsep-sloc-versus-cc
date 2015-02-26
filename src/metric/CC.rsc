module metric::CC

import lang::java::m3::AST;

int calcCC(Statement impl) {
	int result = 1;
	visit (impl) {
		case \if(_,_) : result += 1;	
		case \if(_,_,_) : result += 1;	
		case \case(_) : result += 1;	
		case \do(_,_) : result += 1;
		case \while(_,_) : result += 1;	
		case \for(_,_,_) : result += 1;	
		case \for(_,_,_,_) : result += 1;	
		case foreach(_,_,_) : result += 1;	
		case \catch(_,_): result += 1;
		case \conditional(_,_,_): result += 1;
		case infix(_,"&&",_) : result += 1;
		case infix(_,"||",_) : result += 1;
	}
	return result;
}

int calcInfix(Statement impl) {
	int result = 0;
	visit (impl) {
		case infix(_,"&&",_) : result += 1;
		case infix(_,"||",_) : result += 1;
	}
	return result;
}