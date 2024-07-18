//import Foundation 

class LVM
{
    var dataFile : String
    let SCREEN_WIDTH : Int = 80
    let SCORE_INDENT : Int = 48
    let CONSOLE : UInt8 = 3 
    let IXREGISTER : UInt8 = 4 
    let ASCII_SPACE : UInt8 = 0x20 
    let ASCII_a : UInt8 = 97
    let ASCII_f : UInt8 = 102 
    let ASCII_z : UInt8 = 122
    let ASCII_A : UInt8 = 65
    let ASCII_F : UInt8 = 46
    let ASCII_Z : UInt8 = 90
    let ASCII_0 : UInt8 = 48
    let ASCII_9 : UInt8 = 57

    var A : UInt8 = 0 
    var B : UInt8 = 0
    var D : UInt8 = 0
    var E : UInt8 = 0
    var IX : UInt16 = 0
    var IY : UInt16 = 0

    var ZeroFlag : UInt8 = 1
    var GTFlag : UInt8 = 0
    var LTFlag : UInt8 = 0
    var NegFlag : UInt8 = 0

    var ScreenWidth  : UInt8 = 40
    var ScreenHeight  : UInt8 = 40

    var ObjectTable : UInt16 = 0
    var StringTable : UInt16 = 0

    var PC : UInt16 = 0
    var SP : UInt16 = 0
    var IR  : UInt8 = 0

    var memory : Array<UInt8> = Array(repeating: 0, count: 65536)

    var Immediate8 : UInt8 = 0
    var Immediate16 : UInt16 = 0
    var RamSize : UInt32 = 0
    var type : UInt8 = 0
    var subType : UInt8 = 0
    var mode : UInt8 = 0
    var hPos : UInt8 = 0
    var bufferAddr : UInt16 = 0
    var bufferStart : UInt16 = 0
    var outputChannel : UInt8 = 0
    let OBJECT_ENTRY_SIZE : UInt8 = 21
    let PROPERTY_BYTE_1 : UInt8 = 19
    let PROPERTY_BYTE_2 : UInt8 = 20
    let  masks : [UInt8] = [0, 1, 2, 4, 8, 16, 32, 64, 128,
            1, 2, 4, 8, 16, 32, 64, 128 ]

    let buffer : Array<UInt8> = Array(repeating: 0, count: 80)
    var cmdbuf : Array<UInt8> = Array(repeating: 0, count: 80)
    var topline : Array<UInt8> = Array(repeating: 0, count: 80)
    var debug : UInt8=1
    var breakPoints : Array<UInt16> = Array(repeating: 0, count: 10)
    var numBp : Int = 0
    var step : Int = 0
    var bpOn : Int = 0
 
    init(_ fileName : String)
    {
        self.dataFile = fileName
        self.outputChannel = CONSOLE
    }

    func run()
    { 
        var i : Int = 0
        //var fp : File
        
        let location : String = dataFile
        //let data = NSData(contentsOfFile: dataFile)!
//			fp = fopen( fileName,"rb")
        //if (fp!=0)	
        if (true)
        {
        /*
            fseek(fp, 0, SEEK_END)
            RamSize = ftell(fp)
            rewind(fp)
        //	fseek(fp, 0, SEEK_SET);
            
            
                
            RamSize = fread(memory,1,RamSize,fp)
            fclose(fp)
            Init() //does nothing
            */


            while (true)
            {
        
                if (step == 1)
                {
                    GetDbgCmd()
                    
                    Fetch()
                    Execute()
                    RageDump()
                }
                else
                {
//						for (i=0; i < numBp; i+=1)
                    for i in 0...numBp
                    {
                        if (PC == breakPoints[i])
                        {
//								print("breakpoint at %#04x\n", breakPoints[i])
                            print("breakpoint at \(breakPoints[i])\n")
                            step = 1
                            RageDump()
                            break
                        }
                    }

                    
                    Fetch()
                    Execute() 
                }
            }
            
        }
        else
        {
            print("Unabled to open file.\r\n")
            exit(0)
        }
       
    }
    

    func Init()
    { 
    } 
    
    func Fetch()
    {
        IR = memory[Int(PC)]
        PC+=1

        Decode()
    }

    func Decode()
    {
        type = ((IR & 0xE0) >> 5)  //0x11100000
        subType = (IR & 0x18) >> 3 //0x00011000
        mode = IR & 0x07 //x00000111

        if (type == 0 || type == 1 || type == 2)
        {//load
            if (mode == 4)
            {//one UInt8 immediate
                Immediate8 = FetchByte()
            }
            else if (mode == 6)
            {//two UInt8 immediate
                Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
            }
        }
        else if (type == 3)
        {
            if (subType == 0)
            {//branch
                Immediate8 = FetchByte()
            }
            else if (subType == 1)
            {//jump
                Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
            }
            else if (subType == 2)
            {//call /ret 
                if (mode == 0 || mode == 1 || mode == 6)
                {
                    Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
                }
            }
            else if (subType == 3)
            {
                //these are tests - no immediate data
            }
        }
        else if (type == 4)
        {//inc dec add
            //inc / dec (nn)
            if (subType == 0 || subType == 1)
            {
                if (mode == 4)
                { //dec / inc (nn)
                    Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
                }
            }
            else if (subType == 2 || subType == 3)
            {//add16
                if (mode == 6) {
                    Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
                }
            }
        }
        else if (type == 5)
        {//store 
            if (subType == 2)
            {
                if (mode <= 3)
                {// st r,(nn)
                    Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
                }
            }
            else if (subType == 3)
            {
                if (mode == 6)
                {//load sp,nn
                    Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
                }
            }
        }
        else if (type == 6)
        {
            if (subType == 0)
            {//store ix,iy (nn)
                if (mode == 5 || mode == 7)
                {
                    Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
                }
            }
            else if (subType == 1 || subType == 2)
            {// lda 3,(iy) or (iy)
                Immediate8 = FetchByte()
            }
            else if(subType == 3)
            {//LD IX/SP,??
                if (mode == 0 || mode == 1 || mode == 6) //ld ix,nn
                {
                    Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
                }
            }
        }
        else if (type == 7)
        {
            if (subType == 0 )
            {//ld iy and sp
                if (mode == 0 || mode == 1 || mode == 6)
                {
                    Immediate16 = UInt16(Int(FetchByte()) * 256 + Int(FetchByte()))
                }
            }
        }
    }

    func FetchByte() -> UInt8
    {
        let b : UInt8 = memory[Int(PC)]
        PC+=1
        return b
    }

    func Execute()
    {
        if (type == 0) 
        { 
            Load8() 
        }
        else if (type == 1)
        {
            Compare8()
        }
        else if (type == 2)
        {
            if (subType == 0) { Add8() }
            else if (subType == 1) { Sub8() }
            else if (subType == 2) { And8() }
            else if (subType == 3) { Or8() }
        }
        else if (type == 3)
        {
            if (subType == 0) { Branch() }
            else if (subType == 1) { Jump() }
            else if (subType == 2) { CallOrReturn() }
            else if (subType == 3) { TestOrMul() }
        }
        else if (type == 4)
        {
            if (subType == 0) { Inc() }
            else if (subType == 1) { Dec() }
            else if (subType == 2) { AddIX() }
            else if (subType == 3) { AddIY() }
        }
        else if (type == 5) //101
        {
            if (subType == 0) { Push() }
            else if (subType == 1) { Pop() }
            else if (subType == 2) { StoreRIXNN() }
            else if (subType == 3) { StoreRIY() }
        }
        else if (type == 6)
        {
            if (subType == 0 ) { StoreIXIY() }
            else if (subType == 1) { LoadIndexed() }
            else if (subType == 2) { CompareIndexed() }
            else if (subType == 3) { LoadIX() }
        }
        else if (type == 7 )
        {
            if (subType == 0) { LoadIY() }
            else if (subType == 1) { SpecialOps1() }///????
            else if (subType == 2) { SpecialOps2() }
            else if (subType == 3) { SpecialOps3() }
        }
    }

    func Load8()
    {
        let data : UInt8  = GetSource8()
        SetReg8(data)
    }

    func Compare8()
    {
        let data : UInt8 = GetSource8()
        let tgt : UInt8 = GetTarget8()

        SetFlags( tgt, data)
    }

    func SetFlags(_ tgt:UInt8,_ data: UInt8)
    {
        ZeroFlag = 0
        if (tgt == data) { ZeroFlag = 1 }

        if (tgt > data) { GTFlag = 1 }
        else { GTFlag = 0 }

        if (tgt < data) { LTFlag = 1 }
        else { LTFlag = 0 }
    }

    func SetReg8(_ data : UInt8)
    {
        if (subType == 0) { A = data }
        else if (subType == 1) { B = data }
        else if (subType == 2) { D = data }
        else if (subType == 3) { E = data }
        
        if (data == 0) 
        {
            ZeroFlag = 1
        }
        else 
        {
            ZeroFlag = 0
        }

        if (data < 128)
        {
            NegFlag = 0
        }
        else
        {
            NegFlag = 1
        }   

    }

    func Add8()
    {
        let data : UInt8 = GetSource8()
        A = UInt8(A + data)
        if (A == 0) { ZeroFlag = 1}
        else { ZeroFlag = 0 }
    }

    func Sub8()
    {
        let data : UInt8 = GetSource8()
        A = UInt8(A - data)
        if (A == 0) { ZeroFlag = 1 }
        else { ZeroFlag = 0 }
    }

    func And8()
    {
        let data : UInt8 = GetSource8()
        A = UInt8(A & data)

        if (A == 0) { ZeroFlag = 1 }
        else { ZeroFlag = 0 }
    }

    func Or8()
    {
        let data : UInt8 = GetSource8()
        A = (UInt8)(A | data)

        if (A == 0) { ZeroFlag = 1 }
        else { ZeroFlag = 0 }
    }

    /// <summary>
    /// Store R in IX or NN
    /// </summary>
    func StoreRIXNN()
    {
        let reg : Int = Int(mode) & 3
        var data : UInt8 = 0
        if (reg == 0) {
            data = A
        }
        else if (reg == 1) {
            data = B
        }
        else if (reg == 2) {
            data = D
        }
        else if (reg == 3) {
            data = E
        }

        if (mode < 4)
        {
            memory[Int(Immediate16)] = data
        }
        else  
        {
            memory[Int(IX)] = data
        }
        
    }

    /// <summary>
    /// Store R in IY
    /// </summary>
    func StoreRIY()
    {
        var data : UInt8  = 0
        mode = mode & 3
        
        if (mode == 0) {
            data = A
        }
        else if (mode == 1)
        { 
            data = B
        }
        else if (mode == 2)
        {
                data = D
        }
        else if (mode == 3)
        {
                data = E
        }

        memory[Int(IY)] = data
    }

    func TestOrMul()
    {
        /*
            * TEST	pushzf	011	pushzf	11		000		120	0	1
TEST	pushlt	011	pushlt	11		001		121	0	1
TEST	pushlte	011	pushlte	11		010		122	0	1
TEST	pushgt	011	pushgt	11		011		123	0	1
TEST	pushgte	011	pushgte	11		100		124	0	1
RET	???	011		11		101		125	0	1
RET	???	011		11		110		126	0	1
MUL	MUL	011	MUL	11		111		127	0	1*/
        
        if (mode == 0)
        {//push zf
            memory[Int(SP)] = ZeroFlag
            SP-=1
            memory[Int(SP)] = ZeroFlag
            SP-=1
        }
        else if (mode == 1)
        {//pushlt
            memory[Int(SP)] = LTFlag
            SP-=1
            memory[Int(SP)] = LTFlag
            SP-=1
        }
        else if (mode == 2)
        {//pushlte
            memory[Int(SP)] = UInt8(LTFlag | ZeroFlag)
            SP-=1
            memory[Int(SP)] = UInt8(LTFlag | ZeroFlag)
            SP-=1
        }
        else if (mode == 3)
        {//pushgt
            memory[Int(SP)] = GTFlag
            SP-=1
            memory[Int(SP)] = GTFlag
            SP-=1
        }
        else if (mode == 04)
        {//push gte
            memory[Int(SP)] = UInt8(GTFlag | ZeroFlag)
            SP-=1
            memory[Int(SP)] = UInt8(GTFlag | ZeroFlag)
            SP-=1
        }
        if (mode == 5)
        {//push zf
            var temp : UInt8 = 0
            if (ZeroFlag == 0) {
                temp = 1
            }

            memory[Int(SP)] = temp
            SP-=1
            memory[Int(SP)] = temp
            SP-=1
        }
        else if (mode == 7)
        {
            Mul()
        }
    }

    func Mul()
    {
        let prod : UInt16 = UInt16(A*B)
        A = UInt8(prod / 256)
        B = UInt8(prod % 256)
    }

    func Branch()
    {
        /*
            * 000  = z
001 = nz
010 = lt
011 = gt
100 = lte
101 =gte
110
111
*/
        if (mode == 0 && ZeroFlag == 1) { TakeBranch() }
        else if (mode == 1 && ZeroFlag == 0) { TakeBranch() }
        else if (mode == 2 && LTFlag == 1) { TakeBranch() }
        else if (mode == 3 && GTFlag == 1) { TakeBranch() }
        else if (mode == 4 && (LTFlag == 1 || ZeroFlag == 1 )) { TakeBranch() }
        else if (mode == 5 && (GTFlag == 1 || ZeroFlag == 1 )) { TakeBranch() }//bad op code
        else if (mode == 7 ) { TakeBranch() }
    }


    func Jump()
    {
        /*
        * 000  = z
001 = nz
010 = lt
011 = gt
100 = lte
101 =gte
110
111
*/
        if (mode == 0 && ZeroFlag == 0) { TakeJump() }
        else if (mode == 1 && ZeroFlag == 1) { TakeJump() }
        else if (mode == 1 && LTFlag == 1) { TakeJump() }
        else if (mode == 1 && GTFlag == 1) { TakeJump() }
        else if (mode == 1 && (LTFlag == 1 || ZeroFlag == 1)) { TakeJump() }
        else if (mode == 1 && (GTFlag == 1 || ZeroFlag == 1)) { TakeJump() }
        else if (mode == 7)
        {
            TakeJump()
        }
    }

    func CallOrReturn()
    {
//			print("Call or return, mode=%d\n",mode)
        if (mode == 0 && ZeroFlag==1) {
            DoCall()
        }
        else if (mode == 1 && ZeroFlag==0) {
            DoCall()
        } 
        else if (mode == 5) {
            DoCallIX()
        }
        else if (mode == 2 || mode == 3)
        {
            print("Invalid mode \(mode). PC=\(PC)\n", mode, PC)
            exit(0)
        }
        else if (mode == 6) { DoCall() }
        else if (mode == 7) { Return() }
    }

    func DoCall()
    {
//			print("calling  %#08x\n", Immediate16)
        PushPC()
        PC = Immediate16
    }

    /// <summary>
    /// Call the subroutines stored at the address in IX
    /// </summary>
    func DoCallIX()
    {
        var PCHi : UInt8 = 0
        var PCLo  : UInt8 = 0
        PushPC()
        PCHi = memory[Int(IX)]
        PCLo = memory[Int(IX + 1)]
        PC = UInt16(Int(PCHi) * 256 + Int(PCLo))
    }

    

    func PushPC()
    {
        let PCLo : UInt8 = UInt8(PC % 256)
        let PCHi : UInt8 = UInt8(PC / 256)
        memory[Int(SP)] = PCLo
        SP-=1
        memory[Int(SP)] = PCHi
        SP-=1
    }

    func PopPC()
    {
        var hi : UInt8 = 0
        var lo : UInt8  = 0
        SP+=1
        hi = memory[Int(SP)]
        SP+=1
        lo  = memory[Int(SP)]
        PC = UInt16(Int(hi) * 256 + Int(lo))
    }

    func Return()
    {
//			print("returning\n")
        PopPC()
    }

    func PopIX()
    {
        var lo : UInt8=0
        var hi : UInt8=0
        SP+=1
        hi = memory[Int(SP)]
        SP+=1
        lo = memory[Int(SP)]
        
        IX = UInt16(Int(hi) * 256 + Int(lo))
    }

    func PopIY()
    {
        var lo : UInt8
        var hi : UInt8
        SP+=1
        hi = memory[Int(SP)]
        SP+=1
        lo = memory[Int(SP)]
        
        IY = UInt16(Int(hi) * 256 + Int(lo))
    }

    func TakeBranch()
    {
        var disp : UInt16 = 0
        if (Immediate8 >= 128)
        {
            disp = UInt16((255-Immediate8) + 1)
            PC -=  disp
        }
        else
        {
            PC += UInt16(Immediate8)
        }
    }

    func TakeJump()
    {
        PC = Immediate16
    }


    func GetSource8() -> UInt8
    {
        if (mode == 0) { return A }
        if (mode == 1) { return B }
        if (mode == 2) { return D }
        if (mode == 3) { return E }
        if (mode == 4) { return Immediate8 }
        if (mode == 5) { return memory[Int(IX)] }
        if (mode == 6) { return memory[Int(Immediate16)] }
        if (mode == 7) { return memory[Int(IY)] }
        else
        {
            print("Unknown mode \(mode). PC=(PC)\n")
            exit(0)
            return 0
        }
    }

    func GetTarget8() -> UInt8
    {
        if (subType == 0) { return A }
        else if (subType == 1) { return B }
        else if (subType == 2) { return D }
        else if (subType == 3) { return E }
        else
        {
            print("Unknown mode \(mode). PC=(PC)\n")
            exit(0)
            return 0
        }
    }

    func Inc()
    {
        /*A	000
        B	001 
        D	010 
        E	011
        IX	100
        IY	101
        SP	110
        */
        if (mode == 0)
        {
            A+=1
            if (A == 0) { ZeroFlag = 1 }
            else { ZeroFlag = 0 }
        }
        else if (mode == 1)
        {
            B+=1
            if (B == 0) { ZeroFlag = 1 }
            else { ZeroFlag = 0 }
        }
        else if (mode == 2)
        {
            D+=1
            if (D == 0) { ZeroFlag = 1 }
            else { ZeroFlag = 0 }
        }
        else if (mode == 3)
        {
            E+=1
            if (E == 0) { ZeroFlag = 1 }
            else { ZeroFlag = 0 }
        }
        else if (mode == 4)
        {
            memory[Int(Immediate16)]+=1
            ZeroFlag = 0
            if (memory[Int(Immediate16)] == 0) { ZeroFlag = 1 }
        }
        else if (mode == 5)
        {
            IX+=1 
        }
        else if (mode == 6)
        {
            SP+=1
        }
        else if (mode == 7)
        {
            IY+=1
        }
        
    }
    
    func Dec()
    {
        if (mode == 0)
        {
            A-=1
            if (A == 0) { ZeroFlag = 1 }
            else { ZeroFlag = 0 }
        }
        else if (mode == 1)
        {
            B-=1
            if (B == 0) { ZeroFlag = 1 }
            else { ZeroFlag = 0 }
        }
        else if (mode == 2)
        {
            D-=1
            if (D == 0) { ZeroFlag = 1 }
            else { ZeroFlag = 0 }
        }
        else if (mode == 3)
        {
            E-=1
            if (E == 0) { ZeroFlag = 1 }
            else { ZeroFlag = 0 }
        }
        else if (mode == 4)
        {
            memory[Int(Immediate16)]-=1
            ZeroFlag = 0
            if (memory[Int(Immediate16)] == 0) {
                ZeroFlag = 1
            }
        }
        else if (mode == 5)
        {
            IX-=1
        }
        else if (mode == 6)
        {
            SP-=1
        }
        else if (mode == 7)
        {
            IY-=1
        }

    }
    /*ADD16	"add ix,a"	100	ADD	10	IX	000	A	144	0	1
ADD16	"add ix,b"	100	ADD	10	IX	001	B	145	0	1
ADD16	???	100	???	10		010		146	0	1
ADD16	???	100	???	10		011		147	0	1
ADD16	???	100	???	10		100		148	0	1
ADD16	add ix,ix	100	ADD	10	IX	101	IX	149	0	1
ADD16	add ix,nn	100	ADD	10	IX	110	IX	150	2	3
ADD16	add ix,iy	100	ADD	10	IX	111	IX	151	0	1*/
    func AddIX()
    {
        let data : UInt16 = GetAdd16Data() 
        IX += data
    }

    func AddIY()
    {
        let data : UInt16 = GetAdd16Data()
        IY += data
    }

    func GetAdd16Data()->UInt16
    {
        var  data : UInt16 = 0
        if (mode == 0) 
        {
            data = UInt16(A)
        }
        else if (mode == 1) {
            data = UInt16(B)
        }
        else if (mode == 2) {
            data = UInt16(D)
        }
        else if (mode == 3) {
            data = UInt16(E)
        }
        else if (mode == 5) {
            data = IX
        }
        else if (mode == 6) {
            data = Immediate16
        }
        else if (mode == 7) {
            data = IY
        }
        else
        {
            print("Bad mode in add16. PC=\(PC)\n")
        }
        return data
    }
    

    func Push() 
    {
        if (mode == 7) { PushIY() }
        else if (mode == 6) { PushAll() }
        else if (mode == 5) { PushIX() }
        else if (mode == 4) { PushDE() }
        else
        { 
            Push8()
        }
    }

    func Pop()
    {
        if (mode == 7) { PopIY() }
        else if (mode == 6) { PopAll() }
        else if (mode == 5) { PopIX() }
        else if (mode == 4) { PopDE() }
        else
        {
            PopReg8()
        } 
    }


    func Push8()
    {
        var data : UInt8 = 0
        if (mode == 0) {
            data=A
        }
        else if (mode == 1) {
            data = B
        }
        else if (mode == 2) {
            data = D
        }
        else if (mode == 3) {
            data = E
        }
        memory[Int(SP)] = data
        SP-=1
    }

    func PopReg8()
    {
        let data : UInt8 = Pop8()
        if (mode == 0) {
            A = data
        }
        else if (mode == 1) {
            B = data
        }
        else if (mode == 2) {
            D = data
        }
        else if (mode == 3) {
            E = data
        }
    }

    func Push8ToStack(_ val : UInt8)
    {
        memory[Int(SP)] = val
        SP-=1
    }

    func Pop8()->UInt8
    {
        SP+=1
        return memory[Int(SP)]
    }

    func PushDE()
    {
        Push8ToStack(E)
        Push8ToStack(D)
    }

    func PopDE()
    {
        D = Pop8()
        E = Pop8()
    }

    func PushIX()
    { 
        memory[Int(SP)] = UInt8(IX % 256)
        SP-=1
        memory[Int(SP)] = UInt8(IX / 256)
        SP-=1
    }

    func PushIY()
    {
        memory[Int(SP)] = UInt8(IY % 256)
        SP-=1
        memory[Int(SP)] = UInt8(IY / 256)
        SP-=1
    }

    func PushAll()
    {
        Push8ToStack(A)
        Push8ToStack(B)
        Push8ToStack(D)
        Push8ToStack(E)
        PushIX()
        PushIY()
    }

    func PopAll()
    {
        PopIY()
        PopIX()
        E = Pop8()
        D = Pop8()
        B = Pop8()
        A = Pop8()
    }

    /// <summary>
    /// Stores IX or IY
    /// </summary>
    func StoreIXIY()
    {
        var lo : UInt8 = 0
        var hi : UInt8  = 0
        
        if (mode == 4)
        {//st ix,(iy) 
            memory[Int(IY)] = UInt8(IX / 256)
            memory[Int(IY + 1)] = UInt8(IX % 256)
        }
        else if (mode == 5)
        {//st ix,nn
            hi = UInt8(IX / 256)
            memory[Int(Immediate16)] = hi
            lo = UInt8(IX % 256)
            memory[Int(Immediate16+1)] = lo
        }
        else if (mode == 6)
        {//st iy,(ix) 
            memory[Int(IX)] = (UInt8)(IY/256)
            memory[Int(IX+1)] = (UInt8)(IY%256)
        }
        else if (mode == 7)
        {//st iy,nn
            hi = UInt8(IY / 256)
            memory[Int(Immediate16)] = hi
            lo = UInt8(IY % 256)
            memory[Int(Immediate16 + 1)] = lo
        }
    }

    func LoadIndexed()
    {
        var addr : UInt16 = UInt16(Immediate8)
        if (mode == 5) {
            addr = UInt16(UInt16(Immediate8) + IX)
        }
        else if (mode == 7) {
            addr = UInt16(UInt16(Immediate8) + IY)
        }

        A = memory[Int(addr)]
        if (A == 0) { ZeroFlag = 1 }
        else { ZeroFlag = 0 }
    }

    func CompareIndexed()
    {
        var addr : UInt16 = UInt16(Immediate8)
        var data : UInt8 = 0
        if (mode == 5) {
            addr = UInt16(UInt16(Immediate8) + IX)
        }
        else if (mode == 7) {
            addr = UInt16(UInt16(Immediate8) + IY)
        }

        data = memory[Int(addr)]

        SetFlags(A,data)
    }

    func MakeAddr(_ lo : UInt8, _ hi : UInt8) -> UInt16
    {
        let low : Int = Int(lo)
        let high : Int = Int(hi)
        return UInt16(high * 256 + low)
    }

    func GetLoad16Data() -> UInt16
    {
        var  lo : UInt8 = 0
        var  hi : UInt8 = 0
        
        if (mode == 0)
        {
            return Immediate16
        }
        else if (mode == 1)
        {//(NN)
            hi = memory[Int(Immediate16)]
            lo = memory[Int(Immediate16 + 1)]
            return MakeAddr(lo, hi)
        }
        else if (mode == 2)
        {//(IX)
            hi = memory[Int(IX)]
            lo = memory[Int(IX+1)]
            return MakeAddr(lo, hi)
        }
        else if (mode == 3)
        {//(IY)
            hi = memory[Int(IY)]
            lo = memory[Int(IY + 1)]
            return MakeAddr(lo, hi)
        }
        else if (mode == 4)
        {//SP
            return SP
        }
        else if (mode == 5)
        {//IX
            return IX
        }
        else if (mode == 6)
        {//NN
            return Immediate16
        }
        else if (mode == 7)
        {//IY
            return IY
        }
        RageDump()
        exit(0)
        return 0	
    }

    func LoadIX()
    {
        if (mode == 0) {
            SP = GetLoad16Data()
        }
        else {
            IX = GetLoad16Data()
        }
    }

    func LoadIY()
    {
        if (mode == 0) {
            SP = GetLoad16Data()
        }
        else {
            IY = GetLoad16Data()
        }
    }

    func LoadSP()
    {
        SP = Immediate16
    }

    func SpecialOps1()
    {
        if (mode == 0) { GetObjAttr16() }
        else if (mode == 1) { SetObjAttr16() }
        else if (mode == 2) { PrintStrPtr() }
        else if (mode == 3) { PrintStrPtrCr() }
        else if (mode == 4) { PrintStrN16() }
        else if (mode == 5) { PrintStrN16Cr() }
        else if (mode == 6) { Newline() }
        else if (mode == 7) { RMod() }
    }
    /*
        * Special	RESTORE	111		11			000			248	0	1
Special	SETATTR	111		11			001			249	0	1
Special	SETPROP	111		11			010			250	0	1
Special	GETATTR	111		11			011			251	0	1
Special	GETPROP	111		11			100			252	0	1
Special	GETPARENT	111		11			101			253	0	1
Special	SETENVVAR	111		11			110			254	0	1
Special		111		11			111			255	0	1*/
    func SpecialOps2()
    {
        if (mode == 0) { ReadLine() }
        else if (mode == 1) { CharOut() }
        //else if (mode == 2) SetObjProp()
        else if (mode == 3) { Streq() }
        else if (mode == 4) { AnyKey() }
        else if (mode == 5) { CLS() }
        else if (mode == 6) { Status() }
        else if (mode == 7) { Save() }
    }

    func SpecialOps3()
    {
        if (mode == 0)  { Restore()  }
        else if (mode == 1) { SetObjAttr() }
        else if (mode == 2) { SetObjProp() }
        else if (mode == 3) { GetObjAttr() }
        else if (mode == 4) { GetObjProp() }
        else if (mode == 5) { GetParent() }
        else if (mode == 6) { SetEnv() }
        else if (mode == 7) { Quit() }
    }

        
    
    func ReadLine()
    {    
        /*
        var len : int  = 0
        var i : int = 0
            
            
        //gets(buffer)
        //fgets(buffer, 40, stdin)
        size_t size=40
            
        memset(buffer, 0, 40)
        //gets(buffer)
        fflush (stdin)
        fgets(buffer, 40, stdin)
    //	print("OK\n")
        len = strlen(buffer)
        buffer[len - 1] = 0

        len = strlen(buffer)
            
        //for (;  i < min(len,40); i+=1)
        for i in 0...min(len,40)
        {
            memory[IX + i] = (UInt8)buffer[i]
        }
        
        //null terminate buffer
        //WriteByte((unsigned short)(IX + i) ,0)
        memory[IX + i]=0
    //print("Buffer=Buffer=%s\n",&memory[IX])
    //	print("OK\n")
    */
    }

            

    func AnyKey()
    {
    /*
        fflush(stdin)
        fgetc(stdin)
    */
    }

    func Streq()
    {
        var i : Int  = 0
        while (true)
        {
            let ch1 : UInt8 = memory[Int( Int(IX) + i)]
            let ch2 : UInt8 = memory[Int( Int(IY) + i)]

            if (ucase(ch1) != ucase(ch2))
            {
                A = 0
                return
            }
            //chars are equal
            if (memory[Int(Int(IX) + i)] == 0)  {
                break
            }
            i+=1
        }
        A = 1
    }


    /// <summary>
    /// Prints the string at the address referenced by IX
    /// </summary>
    func PrintStrPtr()
    {
        var i : UInt16 = IX
        var len : Int = 0
        while (memory[Int(i)] != 0)
        {
            len = WordLenIX(i)
            if (len > (ScreenWidth - hPos))
            {
                Newline()
                hPos = 0
            }
            
            //print the word
            i = PrintWord(i)

            if (memory[Int(i)] == 0)
            {
                break
            }

            ChOut(ASCII_SPACE)
            hPos+=1
            i = MoveNextWord(i)
            
        }
    }
    /// <summary>
    /// skips white space and move to the next letter
    /// </summary>
    /// <returns></returns>
    func MoveNextWord(_ i: UInt16) -> UInt16
    {
        var j = Int(i)
        while (memory[j] == ASCII_SPACE)  
        {
            j+=1
        }
        return UInt16(j)
    }

    func PrintWord(_ j : UInt16) -> UInt16
    {
        var i : Int = Int(j)    
        while (memory[Int(i)] != 0 && memory[Int(i)] != ASCII_SPACE)
        {
            ChOut(memory[Int(i)])
            hPos+=1
            i+=1
        }
        return UInt16(i)
    }


    /// <summary>
    /// iy = id#
    /// </summary>
    func PrintStrN16()
    { 
        let ix : UInt16 = IX
        var addr : UInt16 = StringTable
        
//            for (; i < ix; i+=1)
        for _ in 0...ix
        {
            let len : UInt8 = memory[Int(addr)]
            addr += UInt16(len)
            addr += 2 //skip length and null
        }
        addr += 1 //skip length UInt8
        //ix contains addr
        IX = addr
        PrintStrPtr()
        IX = ix
    }

    func PrintStrN16Cr()
    {
        PrintStrN16()
        Newline()
    }

    func PrintStrPtrCr()
    {
        PrintStrPtr()
        Newline()
    }

    func CLS()
    {
        //IMPLEMENT ME LATER
    /*
        print("\x1b[2J") //cls
        print("\x1b[2;0H") //position cursor
        */
    }


    func SetEnv()
    {

        if (A == 1)
        {
            StringTable = IX
        }
        else if (A == 2)
        {
            ObjectTable = IX
        }
        else if (A == 3)
        {
            outputChannel = CONSOLE
        }
        else if (A == 4)
        {
            outputChannel = IXREGISTER
            bufferAddr = IX
            bufferStart = IX
        }
    }

    //ix = start address
    //iy = end address
    func Save()
    {/*
        FILE *fp = 0
        int len = 0
        
        print("Enter save file name (without extension)\n")
        
        memset(buffer, 0, sizeof(char))
        
        //gets_s(buffer, 80);
        //gets(buffer);
        fgets(buffer, 40,stdin)
        len = strlen(buffer)

        buffer[len - 1] = 0;
        strcat(buffer,".sav")
        fp = fopen(buffer, "wb")
        fwrite(&memory[IX], 1, IY-IX, fp)
        fclose(fp)

        print("Game saved.\n")*/
    }
    

    //IX contains starting address to put file data
    func Restore()
    {
        /*
        FILE *fp = 0
        var fileSize : int =0
        var len : int=0

        print("Enter save file name (without extension)\n")
        memset(buffer, 0, sizeof(char))
        //gets(buffer);
        fgets(buffer, 40, stdin)
        len = strlen(buffer)
        buffer[len - 1] = 0
        strcat(buffer,".sav")
        
        fp = fopen(buffer, "rb")
        if (fp != 0)
        {
            print("getting file size...\n")
            fseek(fp, 0, SEEK_END)
            fileSize = ftell(fp)
            rewind(fp)
            print("file size was %d bytes\n", fileSize)		
            fread(&memory[IX], 1, fileSize, fp)
            fclose(fp)
        }
        else
        {
            print("File not found.\n")
        }
        */
    }
    

    func RMod()
    {
        let r : Int  = Int.random(in: 0...65535)
        A = UInt8(r % Int(B))
    }

    func Quit()
    {
        exit(0)
    }


    func CharOut()
    {
        if (A == ASCII_SPACE)
        {
            if (hPos == ScreenWidth - 1)
            {
                Newline()
            }
            else
            {
                ChOut(A)
                hPos+=1
            }
        }
        else
        {
            ChOut(A)
            hPos+=1
        }
    }

    func Newline()
    {
        hPos = 0
        print("\n")
    }

    /// <summary>
    /// scans up to null or space
    /// </summary>
    /// <param name="i"></param>
    /// <returns></returns>
    func WordLenIX(_ j : UInt16) -> Int
    {
        var i = Int(j)
        var count : Int = 0
        
        while (memory[i] != 0) && (memory[i] != ASCII_SPACE)
        {
            count+=1
            i+=1
        }
        return count
    }

    func CalcAttrOffset(_ regD: UInt8, _ regE : UInt8)->UInt16
    {
        return UInt16(
            ObjectTable + (
                UInt16(regD) * UInt16(OBJECT_ENTRY_SIZE)) + UInt16(regE)
            )       
    }

    //ix = table
    //d = object
    //e = attr
    //sets A
    func GetObjAttr()
    {
        let  addr : UInt16 = CalcAttrOffset(D,E)
        A = memory[Int(addr)]
    }

    func GetObjAttr16()
    {
        let  addr : UInt16 = CalcAttrOffset(D,E)
    //    IX = UInt16(memory[Int(addr + 1)] * 256 + memory[Int(addr)]) //flip UInt8s
        IX = MakeAddr(memory[Int(addr)], memory[Int(addr + 1)])
    }

    func SetObjAttr16()
    {
        let addr : UInt16 = CalcAttrOffset(D,E)
        memory[Int(addr)] = UInt8(IX % 256)
        memory[Int(addr+1)] = UInt8(IX / 256)
    }

    //ix = table
    //d = object
    //e = prop # 1 - 16
    //sets A
    func GetObjProp()
    {
        var b : UInt8 = 0
        var mask : UInt8 = 0
        //var addr : UInt16  = UInt16(ObjectTable + D * OBJECT_ENTRY_SIZE)
        var addr : UInt16  = CalcAttrOffset(D,PROPERTY_BYTE_1)
        //addr += PROPERTY_BYTE_1
        if (E > 8)
        {
            addr+=1 //go to next property UInt8
        }

        b =  memory[Int(addr)]
        mask = masks[Int(E)]
        ZeroFlag = 0
        A = 1

        if (  (Int(b) & Int(mask)) == 0)
        {
            ZeroFlag = 1
            A = 0
        }
    }

    //ix = table
    //b = object
    //d = attr
    //e = value 1- 16
    func SetObjProp()
    {
        //var addr : UInt16 = (UInt16)(ObjectTable + B * OBJECT_ENTRY_SIZE + PROPERTY_BYTE_1)
        var addr : UInt16 = CalcAttrOffset(B, PROPERTY_BYTE_1)
        var mask : UInt8 = 0
        var b : UInt8  = 0
        var temp : UInt8  = 0
        if (D > 8)
        {
            addr+=1
        }
        if (E==0)
        {//clear it
            mask = masks[Int(D)]
            mask = ~mask
            b = UInt8(memory[Int(addr)] & mask)
            memory[Int(addr)] = b
        }
        else
        {//set it
            b = memory[Int(addr)]
            temp = UInt8( b | masks[Int(D)] )
            memory[Int(addr)] = temp
        }
        }


    //ix = table
    //b = object
    //d = attr
    //e = value
    func SetObjAttr()
    {
        //var addr : UInt16 = UInt16(ObjectTable + B * OBJECT_ENTRY_SIZE + D)
        let addr : UInt16 = CalcAttrOffset(B,D)
        
        memory[Int(addr)] = E
    }

    //parent of A in A
    func GetParent()
    {
//            var addr : UInt16 = UInt16(ObjectTable + A * OBJECT_ENTRY_SIZE + 1)
        let addr : UInt16 = CalcAttrOffset(A, 1)
        A = memory[Int(addr)]
    }
    
    //ix contains room c
    //iy contains score
    func Status()
    {
        //IMPLEMENT ME LATER!
        /*
        var leng : Int = 0
        var i : Int = 0
        print("\x1b[s") //save cursor
        print("\x1b[0;0H") //home

        sprint(topline,"##### %s ", (char*)&memory[IX] )
        leng = strlen(topline)

        for _ in leng...SCORE_INDENT
        {
            strcat(topline,"#")
        }
        
        strcat(topline," SCORE:")

        strcat(topline,(char*)&memory[IY])
        strcat(topline,"/100")

        var leng = topline.len()

        for _ in leng...SCREEN_WIDTH
        {
            strcat(topline,"#")
        }


        print(topline)
        print("\x1b[u") //restore cursor
            */
    }


    func ChOut(_ ch : UInt8)
    {
        
        if (outputChannel == CONSOLE)
        {
            print(Character(UnicodeScalar(ch)))
        }
        else if (outputChannel == IXREGISTER)
        {
            memory[Int(bufferAddr)] = ch
            bufferAddr+=1
        }
        else
        {
            print("Bad output channel. PC=%d",PC)
            exit(0)
        }
    } 
        
    func cfileexists(_ filename : String ) -> Bool
    {
        /*
        // try to open file to read 
        FILE *file
        if (file = fopen(filename, "r"))
        {
            fclose(file)
            return false
        }
        return true
        */
        return false //place holder
    }

/*
    int min(int x, int y)
    {
        if (x < y) return x
        return y
    }
*/	 
    func ucase(_ ch : UInt8) -> UInt8
    {
        if (ch >= ASCII_a) && (ch <= ASCII_z) 
        {
            return ch-32
        }
        return ch
    }
    
    func GetDbgCmd()
    {/*
        var i : Int = 0
        while (true)
        { 
            fflush(stdin)
            print(":")
            fgets(cmdbuf,40,stdin)
            if (cmdbuf[0] == 0 || cmdbuf[0] == "s")
            {
                step = 1
                break
            }
            if (strcmp(cmdbuf,"r")==0)
            {
                step = 0
                break
            }
            else if (cmdbuf[0] == "r" && cmdbuf[1] != 0)
            {
                breakPoints[numBp] = GetHex(&cmdbuf[1])
                numBp+=1
                print("breakpoint %#04x set.\n",breakPoints[numBp-1])
                step = 0
                break
            }
            else if (cmdbuf[0] == "b")
            {
                breakPoints[numBp] = GetHex(&cmdbuf[1])
                numBp+=1
                print("breakpoint %#04x set.\n",breakPoints[numBp-1])
                step = 0
            }
            else if (cmdbuf[0] == "x")
            {
                var addr : UInt16 = GetHex(&cmdbuf[1])
                for _ in 0...16
                {
                    print("%#02x ",memory[addr])
                    addr+=1
                }
                print("\n")
            }
            else
            {
                print("invalid command.\n")
            }
            fflush(stdin)
        }
        */
        
    }
    
    func RageDump()
    {
        print("PC=%#04x A=%#02x B=%#02x D=%#02x E=%#02x IX=%#04x IY=%#04x\n",
        PC,A,B,D,E,IX,IY)
    }
		
/*
    func GetHex(char *buf) -> UInt16
    {
        var total : UInt16 = 0
        var pow : UInt32 = 1
        var i : Int = 3
        for i in 3.stride(through: 0 , step:-1)
        {
            var char : UInt8 = buf[i]
            if (ch >=ASCII_0) && (ch <= ASCII_9)
            {
                ch=ch-ASCII_0
            }
            else if (ch >=ASCII_A) && (ch <= ASCII_F)
            {
                ch=ch-ASCII_A + 10
            }
            else if (ch >=ASCII_a) && (ch <= ASCII_f)
            {
                ch=ch-ASCII_a + 10
            }
            total += ch*pow
            pow *= 16
        }
        return total
    }
    */

    func min(_ a: Int,_ b : Int) -> Int
    {
        if (a > b) {
            return a
        }
        return b
    }

    func exit(_ code :  Int)
    {
        //place holder
        print("exit not implemented!")
    }

}//end class

func main(_ fileName : String)
{
    let lvm : LVM = LVM(fileName)
    lvm.run()
}

main("heinlein")
