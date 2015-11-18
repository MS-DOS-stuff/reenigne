template<class T> class ROMTemplate : public ISA8BitComponent<ROMTemplate<T>>
{
public:
    static String typeName() { return "ROM"; }
    ROMTemplate(Simulator* simulator, int mask, int address, String fileName,
        int offset)
    {
        _mask = mask | 0xc0000000;
        _start = address;
        String data = File(romData.file(),
            simulator->config()->file().parent(), true).contents();
        int length = ((_start | ~_mask) & 0xfffff) + 1 - _start;
        _data.allocate(length);
        for (int i = 0; i < length; ++i)
            _data[i] = data[i + offset];
        persist("address", &_address, 0, HexPeristenceType(5));
    }
    void setAddress(UInt32 address)
    {
        _address = address & 0xfffff & ~_mask;
        this->_active = ((address & _mask) == _start);
    }
    void read() { this->set(_data[_address & ~_mask]); }
    UInt8 memory(UInt32 address)
    {
        if ((address & _mask) == _start)
            return _data[address & ~_mask];
        return 0xff;
    }
    class Type : public ISA8BitComponent::Type
    {
    public:
        Type(Simulator* simulator) : Component::Type(new Body(simulator)) { }
    private:
        class Body : public ISA8BitComponent::Type::Body
        {
        public:
            Body(Simulator* simulator) : Component::Type::Body(simulator)
            {
                List<StructuredType::Member> members;
                members.add(StructuredType::Member("mask", IntegerType()));
                members.add(StructuredType::Member("address", IntegerType()));
                members.add(StructuredType::Member("fileName", StringType()));
                members.add(StructuredType::Member("fileOffset",
                    Value(IntegerType(), 0)));
                _structuredType = StructuredType(toString(), members);
            }
            String toString() const { return "ROM"; }
            Value tryConvert(const Value& value, String* why) const
            {
                Value stv = value.type().tryConvertTo(_structuredType, value,
                    why);
                if (!stv.valid())
                    return stv;
                auto romMembers = stv.value<HashTable<Identifier, Value>>();
                int mask = romMembers["mask"].value<int>();
                int address = romMembers["address"].value<int>();
                String file = romMembers["fileName"].value<String>();
                int offset = romMembers["fileOffset"].value<int>();
                auto rom = Reference<Component>::create<ROM>(_simulator,
                    mask, address, file, offset);
                _simulator->addComponent(rom);
                return Value(this, rom, value.span());
            }
        private:
            StructuredType _structuredType;
        };
    };
private:
    int _mask;
    int _start;
    int _address;
    Array<UInt8> _data;
};
