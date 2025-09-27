import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { 
  CreditCard, 
  Plus, 
  Search, 
  Download,
  Eye,
  RefreshCw,
  Calendar,
  User,
  Receipt,
  DollarSign,
  TrendingUp,
  AlertCircle,
  CheckCircle,
  Clock,
  XCircle
} from 'lucide-react';
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  getDocs, 
  doc, 
  updateDoc,
  addDoc,
  serverTimestamp 
} from 'firebase/firestore';
import { db } from '../lib/firebase';
import '../App.css';

export default function PaymentManagement() {
  const { patientId } = useParams();
  const { currentUser } = useAuth();
  
  const [payments, setPayments] = useState([]);
  const [invoices, setInvoices] = useState([]);
  const [paymentMethods, setPaymentMethods] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTab, setActiveTab] = useState('payments');
  
  const isDoctorView = currentUser?.role === 'doctor';

  useEffect(() => {
    loadData();
  }, [patientId]);

  const loadData = async () => {
    try {
      setLoading(true);
      
      // Load payments
      const paymentsQuery = query(
        collection(db, 'payments'),
        where('patientId', '==', patientId),
        orderBy('createdAt', 'desc')
      );
      const paymentsSnapshot = await getDocs(paymentsQuery);
      const paymentsData = paymentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      // Load invoices
      const invoicesQuery = query(
        collection(db, 'invoices'),
        where('patientId', '==', patientId),
        orderBy('issueDate', 'desc')
      );
      const invoicesSnapshot = await getDocs(invoicesQuery);
      const invoicesData = invoicesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      // Load payment methods
      const methodsQuery = query(
        collection(db, 'payment_methods'),
        where('patientId', '==', patientId),
        where('isActive', '==', true),
        orderBy('isDefault', 'desc')
      );
      const methodsSnapshot = await getDocs(methodsQuery);
      const methodsData = methodsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      setPayments(paymentsData);
      setInvoices(invoicesData);
      setPaymentMethods(methodsData);
      
      // Calculate analytics
      const analyticsData = calculateAnalytics(paymentsData);
      setAnalytics(analyticsData);
      
    } catch (error) {
      console.error('Error loading payment data:', error);
    } finally {
      setLoading(false);
    }
  };

  const calculateAnalytics = (payments) => {
    const total = payments.length;
    const completed = payments.filter(p => p.status === 'completed').length;
    const pending = payments.filter(p => p.status === 'pending' || p.status === 'processing').length;
    const failed = payments.filter(p => p.status === 'failed' || p.status === 'cancelled').length;
    
    const totalAmount = payments.reduce((sum, p) => sum + (p.totalAmount || 0), 0);
    const completedAmount = payments
      .filter(p => p.status === 'completed')
      .reduce((sum, p) => sum + (p.totalAmount || 0), 0);
    
    // Payment methods breakdown
    const methodCounts = {};
    payments.forEach(p => {
      const method = getPaymentMethodDisplayText(p.method);
      methodCounts[method] = (methodCounts[method] || 0) + 1;
    });
    
    // Payment types breakdown
    const typeCounts = {};
    payments.forEach(p => {
      const type = getPaymentTypeDisplayText(p.type);
      typeCounts[type] = (typeCounts[type] || 0) + 1;
    });

    return {
      totalPayments: total,
      completedPayments: completed,
      pendingPayments: pending,
      failedPayments: failed,
      totalAmount,
      completedAmount,
      averagePayment: completed > 0 ? completedAmount / completed : 0,
      successRate: total > 0 ? (completed / total) * 100 : 0,
      paymentMethods: methodCounts,
      paymentTypes: typeCounts
    };
  };

  const formatDate = (timestamp) => {
    if (!timestamp) return 'N/A';
    const date = new Date(timestamp.seconds * 1000);
    return date.toLocaleDateString();
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount || 0);
  };

  const getPaymentStatusColor = (status) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'pending':
      case 'processing':
        return 'bg-yellow-100 text-yellow-800';
      case 'failed':
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      case 'refunded':
      case 'partiallyRefunded':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getPaymentStatusIcon = (status) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="h-4 w-4" />;
      case 'pending':
      case 'processing':
        return <Clock className="h-4 w-4" />;
      case 'failed':
      case 'cancelled':
        return <XCircle className="h-4 w-4" />;
      case 'refunded':
      case 'partiallyRefunded':
        return <RefreshCw className="h-4 w-4" />;
      default:
        return <AlertCircle className="h-4 w-4" />;
    }
  };

  const getPaymentTypeDisplayText = (type) => {
    const types = {
      consultation: 'Consultation',
      prescription: 'Prescription',
      labTest: 'Lab Test',
      procedure: 'Procedure',
      subscription: 'Subscription',
      copay: 'Co-pay',
      deductible: 'Deductible',
      other: 'Other'
    };
    return types[type] || type;
  };

  const getPaymentMethodDisplayText = (method) => {
    const methods = {
      creditCard: 'Credit Card',
      debitCard: 'Debit Card',
      paypal: 'PayPal',
      applePay: 'Apple Pay',
      googlePay: 'Google Pay',
      bankTransfer: 'Bank Transfer',
      cash: 'Cash',
      insurance: 'Insurance'
    };
    return methods[method] || method;
  };

  const getPaymentMethodIcon = (type) => {
    switch (type) {
      case 'card':
        return <CreditCard className="h-5 w-5" />;
      case 'paypal':
        return <DollarSign className="h-5 w-5" />;
      default:
        return <CreditCard className="h-5 w-5" />;
    }
  };

  const requestRefund = async (payment, amount, reason) => {
    try {
      const refundRequest = {
        paymentId: payment.id,
        amount: amount,
        reason: reason,
        status: 'requested',
        requestedAt: serverTimestamp(),
        createdAt: serverTimestamp()
      };

      await addDoc(collection(db, 'refund_requests'), refundRequest);
      
      // Update payment refund status
      await updateDoc(doc(db, 'payments', payment.id), {
        refundStatus: 'requested',
        updatedAt: serverTimestamp()
      });

      alert('Refund request submitted successfully');
      loadData();
    } catch (error) {
      console.error('Error requesting refund:', error);
      alert('Error requesting refund');
    }
  };

  const setDefaultPaymentMethod = async (methodId) => {
    try {
      // First, unset all other default methods
      const methodsToUpdate = paymentMethods.filter(m => m.isDefault && m.id !== methodId);
      for (const method of methodsToUpdate) {
        await updateDoc(doc(db, 'payment_methods', method.id), {
          isDefault: false,
          updatedAt: serverTimestamp()
        });
      }

      // Set the selected method as default
      await updateDoc(doc(db, 'payment_methods', methodId), {
        isDefault: true,
        updatedAt: serverTimestamp()
      });

      alert('Default payment method updated');
      loadData();
    } catch (error) {
      console.error('Error setting default payment method:', error);
      alert('Error updating default payment method');
    }
  };

  const deletePaymentMethod = async (methodId) => {
    if (confirm('Are you sure you want to delete this payment method?')) {
      try {
        await updateDoc(doc(db, 'payment_methods', methodId), {
          isActive: false,
          updatedAt: serverTimestamp()
        });

        alert('Payment method deleted');
        loadData();
      } catch (error) {
        console.error('Error deleting payment method:', error);
        alert('Error deleting payment method');
      }
    }
  };

  const filteredPayments = payments.filter(payment => {
    if (!searchQuery) return true;
    return (
      payment.description?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      payment.invoiceNumber?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      getPaymentTypeDisplayText(payment.type).toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">
            {isDoctorView ? 'Patient Payments' : 'Payments & Billing'}
          </h1>
          <p className="text-gray-600">Manage payments, invoices, and billing information</p>
        </div>
        
        <div className="flex space-x-2">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
            <Input
              placeholder="Search payments..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 w-64"
            />
          </div>
          {!isDoctorView && (
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              Add Payment Method
            </Button>
          )}
          <Button variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
        </div>
      </div>

      {/* Quick Stats */}
      {analytics && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-2">
                <DollarSign className="h-5 w-5 text-green-600" />
                <div>
                  <p className="text-2xl font-bold">{formatCurrency(analytics.completedAmount)}</p>
                  <p className="text-sm text-gray-600">Total Paid</p>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-2">
                <CheckCircle className="h-5 w-5 text-green-600" />
                <div>
                  <p className="text-2xl font-bold">{analytics.completedPayments}</p>
                  <p className="text-sm text-gray-600">Completed</p>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-2">
                <Clock className="h-5 w-5 text-yellow-600" />
                <div>
                  <p className="text-2xl font-bold">{analytics.pendingPayments}</p>
                  <p className="text-sm text-gray-600">Pending</p>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-2">
                <TrendingUp className="h-5 w-5 text-blue-600" />
                <div>
                  <p className="text-2xl font-bold">{analytics.successRate.toFixed(1)}%</p>
                  <p className="text-sm text-gray-600">Success Rate</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Main Content */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="payments">Payments</TabsTrigger>
          <TabsTrigger value="invoices">Invoices</TabsTrigger>
          <TabsTrigger value="methods">Payment Methods</TabsTrigger>
          {isDoctorView && <TabsTrigger value="analytics">Analytics</TabsTrigger>}
          <TabsTrigger value="history">History</TabsTrigger>
        </TabsList>

        {/* Payments Tab */}
        <TabsContent value="payments" className="space-y-4">
          {filteredPayments.length === 0 ? (
            <Card>
              <CardContent className="p-12 text-center">
                <CreditCard className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No Payments Found</h3>
                <p className="text-gray-600">There are no payments to display.</p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid gap-4">
              {filteredPayments.slice(0, 10).map((payment) => (
                <Card key={payment.id}>
                  <CardContent className="p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex-1">
                        <h3 className="text-lg font-semibold text-gray-900">
                          {payment.description || getPaymentTypeDisplayText(payment.type)}
                        </h3>
                        <p className="text-2xl font-bold text-green-600">
                          {formatCurrency(payment.totalAmount)}
                        </p>
                      </div>
                      <Badge className={getPaymentStatusColor(payment.status)}>
                        <div className="flex items-center space-x-1">
                          {getPaymentStatusIcon(payment.status)}
                          <span>{payment.status?.toUpperCase()}</span>
                        </div>
                      </Badge>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                      <div className="flex items-center space-x-2">
                        <CreditCard className="h-4 w-4 text-gray-500" />
                        <span className="text-sm">{getPaymentMethodDisplayText(payment.method)}</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Calendar className="h-4 w-4 text-gray-500" />
                        <span className="text-sm">{formatDate(payment.createdAt)}</span>
                      </div>
                      {payment.doctorName && (
                        <div className="flex items-center space-x-2">
                          <User className="h-4 w-4 text-gray-500" />
                          <span className="text-sm">Dr. {payment.doctorName}</span>
                        </div>
                      )}
                    </div>

                    {payment.invoiceNumber && (
                      <div className="mb-4 p-3 bg-gray-50 rounded-lg">
                        <div className="flex items-center space-x-2">
                          <Receipt className="h-4 w-4 text-gray-600" />
                          <span className="text-sm font-medium">Invoice: {payment.invoiceNumber}</span>
                        </div>
                      </div>
                    )}

                    {payment.failureReason && (
                      <div className="mb-4 p-3 bg-red-50 rounded-lg">
                        <div className="flex items-center space-x-2">
                          <AlertCircle className="h-4 w-4 text-red-600" />
                          <span className="text-sm font-medium">Failure Reason:</span>
                        </div>
                        <p className="text-sm text-red-700 mt-1">{payment.failureReason}</p>
                      </div>
                    )}

                    <div className="flex space-x-2">
                      <Button variant="outline" size="sm">
                        <Eye className="h-4 w-4 mr-2" />
                        View Details
                      </Button>
                      
                      {payment.status === 'completed' && payment.refundStatus !== 'requested' && !isDoctorView && (
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => {
                            const reason = prompt('Enter reason for refund:');
                            if (reason) {
                              requestRefund(payment, payment.totalAmount, reason);
                            }
                          }}
                        >
                          <RefreshCw className="h-4 w-4 mr-2" />
                          Request Refund
                        </Button>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Invoices Tab */}
        <TabsContent value="invoices" className="space-y-4">
          {invoices.length === 0 ? (
            <Card>
              <CardContent className="p-12 text-center">
                <Receipt className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No Invoices Found</h3>
                <p className="text-gray-600">There are no invoices to display.</p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid gap-4">
              {invoices.map((invoice) => (
                <Card key={invoice.id}>
                  <CardContent className="p-6">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <h3 className="text-lg font-semibold text-gray-900">
                          Invoice {invoice.invoiceNumber}
                        </h3>
                        <p className="text-xl font-bold text-blue-600">
                          {formatCurrency(invoice.totalAmount)}
                        </p>
                        <p className="text-sm text-gray-600">
                          Issued: {formatDate(invoice.issueDate)}
                        </p>
                        {invoice.dueDate && (
                          <p className="text-sm text-gray-600">
                            Due: {formatDate(invoice.dueDate)}
                          </p>
                        )}
                      </div>
                      <Badge className={invoice.status === 'paid' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}>
                        {invoice.status?.toUpperCase()}
                      </Badge>
                    </div>

                    <div className="mt-4 flex space-x-2">
                      <Button variant="outline" size="sm">
                        <Eye className="h-4 w-4 mr-2" />
                        View Invoice
                      </Button>
                      <Button variant="outline" size="sm">
                        <Download className="h-4 w-4 mr-2" />
                        Download PDF
                      </Button>
                      {invoice.status !== 'paid' && (
                        <Button size="sm">
                          Pay Now
                        </Button>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Payment Methods Tab */}
        <TabsContent value="methods" className="space-y-4">
          {paymentMethods.length === 0 ? (
            <Card>
              <CardContent className="p-12 text-center">
                <CreditCard className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No Payment Methods</h3>
                <p className="text-gray-600">Add a payment method to get started.</p>
                <Button className="mt-4">
                  <Plus className="h-4 w-4 mr-2" />
                  Add Payment Method
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="grid gap-4">
              {paymentMethods.map((method) => (
                <Card key={method.id}>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        {getPaymentMethodIcon(method.type)}
                        <div>
                          <h3 className="font-semibold">
                            {method.brand?.toUpperCase()} •••• {method.last4}
                          </h3>
                          {method.expiryMonth && method.expiryYear && (
                            <p className="text-sm text-gray-600">
                              Expires {method.expiryMonth}/{method.expiryYear}
                            </p>
                          )}
                          {method.isDefault && (
                            <Badge className="bg-green-100 text-green-800 mt-1">
                              Default
                            </Badge>
                          )}
                        </div>
                      </div>
                      
                      <div className="flex space-x-2">
                        {!method.isDefault && (
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => setDefaultPaymentMethod(method.id)}
                          >
                            Set Default
                          </Button>
                        )}
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => deletePaymentMethod(method.id)}
                        >
                          Delete
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Analytics Tab */}
        {isDoctorView && (
          <TabsContent value="analytics" className="space-y-6">
            {analytics && (
              <>
                {/* Revenue Overview */}
                <Card>
                  <CardHeader>
                    <CardTitle>Revenue Overview</CardTitle>
                    <CardDescription>Payment statistics and trends</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                      <div className="text-center p-4 bg-green-50 rounded-lg">
                        <p className="text-2xl font-bold text-green-600">{formatCurrency(analytics.totalAmount)}</p>
                        <p className="text-sm text-gray-600">Total Revenue</p>
                      </div>
                      <div className="text-center p-4 bg-blue-50 rounded-lg">
                        <p className="text-2xl font-bold text-blue-600">{formatCurrency(analytics.averagePayment)}</p>
                        <p className="text-sm text-gray-600">Average Payment</p>
                      </div>
                      <div className="text-center p-4 bg-purple-50 rounded-lg">
                        <p className="text-2xl font-bold text-purple-600">{analytics.successRate.toFixed(1)}%</p>
                        <p className="text-sm text-gray-600">Success Rate</p>
                      </div>
                      <div className="text-center p-4 bg-orange-50 rounded-lg">
                        <p className="text-2xl font-bold text-orange-600">{analytics.totalPayments}</p>
                        <p className="text-sm text-gray-600">Total Transactions</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* Payment Methods Breakdown */}
                <Card>
                  <CardHeader>
                    <CardTitle>Payment Methods</CardTitle>
                    <CardDescription>Breakdown by payment method</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      {Object.entries(analytics.paymentMethods).map(([method, count]) => (
                        <div key={method} className="flex justify-between items-center">
                          <span className="font-medium">{method}</span>
                          <Badge variant="outline">{count} payments</Badge>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>

                {/* Payment Types Breakdown */}
                <Card>
                  <CardHeader>
                    <CardTitle>Payment Types</CardTitle>
                    <CardDescription>Breakdown by service type</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      {Object.entries(analytics.paymentTypes).map(([type, count]) => (
                        <div key={type} className="flex justify-between items-center">
                          <span className="font-medium">{type}</span>
                          <Badge variant="outline">{count} payments</Badge>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </>
            )}
          </TabsContent>
        )}

        {/* History Tab */}
        <TabsContent value="history" className="space-y-4">
          <div className="grid gap-4">
            {payments.map((payment) => (
              <Card key={payment.id}>
                <CardContent className="p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-gray-900">
                        {payment.description || getPaymentTypeDisplayText(payment.type)}
                      </h3>
                      <p className="text-lg font-bold text-gray-900">
                        {formatCurrency(payment.totalAmount)}
                      </p>
                      <p className="text-sm text-gray-600">
                        {formatDate(payment.createdAt)} • {getPaymentMethodDisplayText(payment.method)}
                      </p>
                    </div>
                    <Badge className={getPaymentStatusColor(payment.status)}>
                      {payment.status?.toUpperCase()}
                    </Badge>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}

