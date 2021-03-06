#include "IObjectState.hpp"
#include "IObject.h"
#include "shared_ptr.hpp"
#ifdef CV_XADD
  // allow to use user-defined macro
#elif defined __GNUC__ || defined __clang__
#  if defined __clang__ && __clang_major__ >= 3 && !defined __ANDROID__ && !defined __EMSCRIPTEN__ && !defined(__CUDACC__)
#    ifdef __ATOMIC_ACQ_REL
#      define CV_XADD(addr, delta) __c11_atomic_fetch_add((_Atomic(int)*)(addr), delta, __ATOMIC_ACQ_REL)
#    else
#      define CV_XADD(addr, delta) __atomic_fetch_add((_Atomic(int)*)(addr), delta, 4)
#    endif
#  else
#    if defined __ATOMIC_ACQ_REL && !defined __clang__
       // version for gcc >= 4.7
#      define CV_XADD(addr, delta) (int)__atomic_fetch_add((unsigned*)(addr), (unsigned)(delta), __ATOMIC_ACQ_REL)
#    else
#      define CV_XADD(addr, delta) (int)__sync_fetch_and_add((unsigned*)(addr), (unsigned)(delta))
#    endif
#  endif
#elif defined _MSC_VER && !defined RC_INVOKED
#  include <intrin.h>
#  define CV_XADD(addr, delta) (int)_InterlockedExchangeAdd((long volatile*)addr, delta)
#else
   CV_INLINE CV_XADD(int* addr, int delta) { int tmp = *addr; *addr += delta; return tmp; }
#endif

IObjectSharedState* IObjectSharedState::Get(const IObject* obj)
{
    return obj->GetConstructor()->GetState(obj->GetPerTypeId());
}

IObjectSharedState::IObjectSharedState(IObject* obj, IObjectConstructor* constructor)
{
    object_ref_count = 0;
    state_ref_count = 0;
    object = obj;
    this->constructor = constructor;
    id = obj->GetPerTypeId();
}

IObjectSharedState::~IObjectSharedState()
{
    if(object)
    {
        delete object;
        object = 0;
    }
    constructor->DeRegister(id);
}

IObject* IObjectSharedState::GetIObject()
{
    return object;
}

rcc::shared_ptr<IObject> IObjectSharedState::GetSharedPtr()
{
    return rcc::shared_ptr<IObject>(this);
}

rcc::weak_ptr<IObject> IObjectSharedState::GetWeakPtr()
{
    return rcc::weak_ptr<IObject>(this);
}

void IObjectSharedState::IncrementObject()
{
    CV_XADD(&object_ref_count, 1);
}

void IObjectSharedState::IncrementState()
{
    CV_XADD(&state_ref_count, 1);
}

void IObjectSharedState::DecrementObject()
{
    CV_XADD(&object_ref_count, -1);
    if(object_ref_count == 0)
    {
        delete object;
        object = 0;
    }
}

void IObjectSharedState::DecrementState()
{
    CV_XADD(&state_ref_count, -1);
    if(state_ref_count == 0)
    {
        delete this;
    }
}
void IObjectSharedState::SetObject(IObject* obj)
{
    object = obj;
}
void IObjectSharedState::SetConstructor(IObjectConstructor* constructor)
{
    this->constructor = constructor;
}
int IObjectSharedState::ObjectCount() const
{
    return object_ref_count;
}
int IObjectSharedState::StateCount() const
{
    return state_ref_count;
}
