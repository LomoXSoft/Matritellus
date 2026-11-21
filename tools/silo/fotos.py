"""The flat photos of the Silo del Tío Colorao on its Google Maps page (ten, 2021-2024): python tools/silo/fotos.py OUT_FOLDER
Other people's pictures: NOT kept in the repository, only this list of their keys."""
import sys, os, urllib.request
OUT = sys.argv[1]
IDS = ['ANWiy9Q322wXW99QbrdCFKSMODC9CVF9JQmVEBngg8t-HaFDS1DbmTbsJVtviUxo6udCxOkHkHaxkAMqnb3x_yTA0oDSx1CHJcXAmuSERKnWsDqVaMnOye4f3JMLqZlp294R4IoyVhTN',
 'ANWiy9SlLSzbGvuwPi0ST_wTrH2c1mfVC78CMrFD2caUXZZprTLT5jXJSd_2aqZSBxdzwIYS6OyUpLccA7nCMIPPm_rgSTCxUwiqQRhl5dKVSX3XGp4Fjy7lkDY1CwQNsxWPohISMHoB',
 'ANWiy9RY3GUWbnT6GYpB0-kxFv9rvMUyctwqlb-TTBtIS7cJtCm51Xq0YzD_H7Gah1Bqx1fDe1U0P0JGmUyFt301STFf25mqHaktjypFk8zJLthLbwDXJnEkfnDmTQs7EQa8ayGP9kABhom_Vr62',
 'ANWiy9Qm9snr461sja-JRNPMRFf6y-S3QgsNX1Nm75Z3Afy9jxd-hPt7poTbF-wg9vPWSMDVDSJcWa35BPhnskJde-DbbZFXAMsg4xnAg2YvCzpWBIBNJosHRgCoUQ-JCCw-iS4lJQW7',
 'ANWiy9QGkA8iqS_XZirRlIJTiVRLMAAI8LYfViK_bxnLWEeCrRJg8tgjk4lRMJVqlTw5mNbqlizMGVc4lkWsCGguH9Prm6cxOmLP42IarAbSTaDDSDb1ayqcNc4k3OmX5y5qaOnzvF4S',
 'ANWiy9TIXkCzgLEbPBbMAyoryxgApJ8irhlfzi2RWqbxCpWLOYSKPedFIJppCDW74mHXZvc4vRv9pkyq6ZOl7k1maNaW-oWZmBO3E1XhVvFFvIXHc61u0ex87If0ClhPQKEsBc0U1xil',
 'ANWiy9Sjk79EdfSr3cvDuFjNoN2DBUEH8uqXoH0meWxNsjq6KXnmRVWzVlaUsaQgowwA23aKd3aWZojlGN1F62o83LpCYj2updM5kYWG4rE6eQo9ZGpRz2cpnFaRzmMvcHKMvQjPOVJX',
 'ANWiy9Qalqas7Tdnt1-gOF4LWKAnsE2riCnIBfrUTFyUlyJ4teZrD5XdGsTrDhxpKqGnpeD9tEnjEo477m-UtqDNBie4p68NWaUg1VLqRniAxIFr3JULs5p8GvrwtyxRAFxnB_mX5wI',
 'ANWiy9RxsEHF7Eo431joeSSnfjeWG7o2PSmax2BLnLkjlz0_UnZAHjJdMM7QCO17X3D3G8lNclG4BjhcCvzf3vDm5Y_9_N7ge7_we9TUzG8FdrD0v1sSDDUkhFzQGgOex77EHURamv9h',
 'ANWiy9Ss_GXL1vovwT5oUFcUkM-r2WB_GPzpkcgOPOcfuqZBaa__pRq6zUFea0HgwPm0XV6HB3I9uJ3t3NPEFyORpMkunAU2jDjNoVhYCncnkycXDZF3EDykNE5UiYlabT-EMlPybUiPRw']
for i, pid in enumerate(IDS):
    f = os.path.join(OUT, 'f%02d.jpg' % (i + 1))
    if os.path.exists(f): continue
    url = 'https://lh3.googleusercontent.com/gps-cs-s/%s=w2048-h2048-k-no' % pid
    try:
        data = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (map-tool)'}), timeout=60).read()
        open(f, 'wb').write(data); print(f, len(data))
    except Exception as e:
        print('fail', i + 1, e)
